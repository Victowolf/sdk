// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/messages.dart'
    show
        LocatedMessage,
        Message,
        messageMoreThanOneSuperInitializer,
        messageRedirectingConstructorWithAnotherInitializer,
        messageRedirectingConstructorWithMultipleRedirectInitializers,
        messageRedirectingConstructorWithSuperInitializer,
        messageSuperInitializerNotLast,
        noLength,
        templateCantInferTypeDueToCircularity;
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart'
    show DelayedDefaultValueCloner, TypeDependency;
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_inference_engine.dart';
import 'constructor_declaration.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';
import 'source_property_builder.dart';

abstract class SourceConstructorBuilder implements ConstructorBuilder {
  @override
  DeclarationBuilder get declarationBuilder;

  void buildOutlineNodes(BuildNodesCallback f);

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  int buildBodyNodes(BuildNodesCallback f);

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes(ClassHierarchyBase hierarchy);

  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  /// Returns `true` if this constructor is an redirecting generative
  /// constructor.
  ///
  /// It is considered redirecting if it has at least one redirecting
  /// initializer.
  bool get isRedirecting;

  @override
  Uri get fileUri;
}

class SourceConstructorBuilderImpl extends SourceMemberBuilderImpl
    implements
        SourceConstructorBuilder,
        SourceMemberBuilder,
        Inferable,
        ConstructorDeclarationBuilder {
  final Modifiers modifiers;

  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  /// The introductory declaration for this constructor.
  final ConstructorDeclaration _introductory;

  /// The augmenting declarations for this constructor.
  final List<ConstructorDeclaration> _augmentations;

  /// All constructor declarations for this constructor that are augmented by
  /// at least one constructor declaration.
  late final List<ConstructorDeclaration> _augmentedDeclarations;

  /// The last constructor declaration between [_introductory] and
  /// [_augmentations].
  ///
  /// This is the declaration that creates the emitted kernel member(s).
  late final ConstructorDeclaration _lastDeclaration;

  final MemberName _memberName;

  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners = [];

  Set<SourcePropertyBuilder>? _initializedFields;

  late final Reference _invokeTargetReference;
  late final Member _invokeTarget;
  late final Reference _readTargetReference;
  late final Member _readTarget;

  SourceConstructorBuilderImpl({
    required this.modifiers,
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.fileOffset,
    required this.fileUri,
    this.nativeMethodName,
    required Reference? constructorReference,
    required Reference? tearOffReference,
    required NameScheme nameScheme,
    required ConstructorDeclaration introductory,
    List<ConstructorDeclaration> augmentations = const [],
  })  : _introductory = introductory,
        _augmentations = augmentations,
        _memberName = nameScheme.getDeclaredName(name) {
    if (augmentations.isEmpty) {
      _augmentedDeclarations = augmentations;
      _lastDeclaration = introductory;
    } else {
      _augmentedDeclarations = [_introductory, ..._augmentations];
      _lastDeclaration = _augmentedDeclarations.removeLast();
    }
    for (ConstructorDeclaration declaration in _augmentedDeclarations) {
      declaration.createNode(
          name: name,
          libraryBuilder: libraryBuilder,
          nameScheme: nameScheme,
          constructorReference: null,
          tearOffReference: null);
    }
    _lastDeclaration.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference);
    _invokeTargetReference = _lastDeclaration.invokeTargetReference;
    _invokeTarget = _lastDeclaration.invokeTarget;
    _readTargetReference = _lastDeclaration.readTargetReference;
    _readTarget = _lastDeclaration.readTarget;

    _introductory.registerInferable(this);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.registerInferable(this);
    }
  }

  @override
  Builder get parent => declarationBuilder;

  bool get hasParameters => _introductory.formals != null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => modifiers.isAugment;

  @override
  bool get isExternal => modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => modifiers.isAbstract;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  bool get isAugment => modifiers.isAugment;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  bool get isRedirecting => _lastDeclaration.isRedirecting;

  @override
  // Coverage-ignore(suite): Not run.
  Builder get getable => this;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get setable => null;

  @override
  Member get readTarget => _readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _readTargetReference;

  @override
  Member get invokeTarget => _invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _invokeTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [invokeTargetReference];

  // TODO(johnniwinther): Add annotations to tear-offs.
  Iterable<Annotatable> get annotatables => [invokeTarget];

  @override
  FunctionNode get function => _lastDeclaration.function;

  void becomeNative(SourceLoader loader) {
    _introductory.becomeNative();
    for (ConstructorDeclaration augmentation in _augmentations) {
      // Coverage-ignore-block(suite): Not run.
      augmentation.becomeNative();
    }
    for (Annotatable annotatable in annotatables) {
      loader.addNativeAnnotation(annotatable, nativeMethodName!);
    }
  }

  late final Substitution _fieldTypeSubstitution =
      _introductory.computeFieldTypeSubstitution(declarationBuilder);

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _fieldTypeSubstitution.substituteType(fieldType);
  }

  final String? nativeMethodName;

  // Coverage-ignore(suite): Not run.
  bool get isNative => nativeMethodName != null;

  @override
  bool get isConstructor => true;

  List<Initializer> get _initializers => _lastDeclaration.initializers;

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  void _injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper, TreeNode parent) {
    Initializer lastInitializer = _initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    _initializers.add(error..parent = parent);
    _initializers.add(lastInitializer);
  }

  @override
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult,
      required TreeNode parent}) {
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        _injectInvalidInitializer(messageMoreThanOneSuperInitializer,
            initializer.fileOffset, "super".length, helper, parent);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            initializer.fileOffset,
            "super".length,
            helper,
            parent);
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        superInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.fileOffset,
                  arguments: initializer.arguments,
                  isSuper: true,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer!.fileOffset,
            "super".length,
            helper,
            parent);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithMultipleRedirectInitializers,
            initializer.fileOffset,
            noLength,
            helper,
            parent);
      } else if (_initializers.isNotEmpty) {
        // Error on all previous ones.
        for (int i = 0; i < _initializers.length; i++) {
          Initializer initializer = _initializers[i];
          int length = noLength;
          if (initializer is AssertInitializer) length = "assert".length;
          Initializer error = helper.buildInvalidInitializer(
              helper.buildProblem(
                  messageRedirectingConstructorWithAnotherInitializer,
                  initializer.fileOffset,
                  length));
          error.parent = parent;
          _initializers[i] = error;
        }
        inferenceResult?.applyResult(_initializers, parent);
        _initializers.add(initializer..parent = parent);
        redirectingInitializer = initializer;
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        redirectingInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, const <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.fileOffset,
                  arguments: initializer.arguments,
                  isSuper: false,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _injectInvalidInitializer(
          messageRedirectingConstructorWithAnotherInitializer,
          initializer.fileOffset,
          length,
          helper,
          parent);
    } else if (superInitializer != null) {
      _injectInvalidInitializer(messageSuperInitializerNotLast,
          initializer.fileOffset, noLength, helper, parent);
    } else {
      inferenceResult?.applyResult(_initializers, parent);
      _initializers.add(initializer..parent = parent);
    }
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = _introductory.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
    for (ConstructorDeclaration augmentation in _augmentations) {
      count += augmentation.computeDefaultTypes(context,
          inErrorRecovery: inErrorRecovery);
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    _introductory.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRegularMethod => false;

  @override
  bool get isGetter => false;

  @override
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isOperator => false;

  @override
  bool get isFactory => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _lastDeclaration.buildOutlineNodes(f,
        constructorBuilder: this,
        libraryBuilder: libraryBuilder,
        declarationConstructor: invokeTarget,
        delayedDefaultValueCloners: _delayedDefaultValueCloners);
    for (ConstructorDeclaration declaration in _augmentedDeclarations) {
      declaration.buildOutlineNodes(noAddBuildNodesCallback,
          constructorBuilder: this,
          libraryBuilder: libraryBuilder,
          declarationConstructor: invokeTarget,
          delayedDefaultValueCloners: _delayedDefaultValueCloners);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    _introductory.buildBody();
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.buildBody();
    }
    return _augmentations.length;
  }

  @override
  void registerInitializedField(SourcePropertyBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  @override
  Set<SourcePropertyBuilder>? takeInitializedFields() {
    Set<SourcePropertyBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }

  @override
  void prepareInitializers() {
    _introductory.prepareInitializers();
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.prepareInitializers();
    }
    redirectingInitializer = null;
    superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    _lastDeclaration.prependInitializer(initializer);
  }

  bool _hasBuiltOutlines = false;
  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;

    if (!hasBuiltOutlineExpressions) {
      _introductory.buildOutlineExpressions(
          annotatables: annotatables,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          constructorBuilder: this,
          classHierarchy: classHierarchy,
          createFileUriExpression:
              _invokeTarget.fileUri != _introductory.fileUri,
          delayedDefaultValueCloners: delayedDefaultValueCloners);
      for (ConstructorDeclaration augmentation in _augmentations) {
        augmentation.buildOutlineExpressions(
            annotatables: annotatables,
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            constructorBuilder: this,
            classHierarchy: classHierarchy,
            createFileUriExpression:
                _invokeTarget.fileUri != augmentation.fileUri,
            delayedDefaultValueCloners: delayedDefaultValueCloners);
      }
      hasBuiltOutlineExpressions = true;
    }

    delayedDefaultValueCloners.addAll(_delayedDefaultValueCloners);
    _delayedDefaultValueCloners.clear();
    _hasBuiltOutlines = true;
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isDeclarationInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassInstanceMember => false;

  @override
  bool get isEffectivelyExternal {
    bool isExternal = this.isExternal;
    if (isExternal) {
      for (ConstructorDeclaration augmentation in _augmentations) {
        isExternal &= augmentation.isExternal;
      }
    }
    return isExternal;
  }

  @override
  bool get isEffectivelyRedirecting {
    bool isRedirecting = _introductory.isRedirecting;
    if (!isRedirecting) {
      for (ConstructorDeclaration augmentation in _augmentations) {
        isRedirecting |= augmentation.isRedirecting;
      }
    }
    return isRedirecting;
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferFormalTypes(hierarchy);
  }

  bool _hasFormalsInferred = false;

  @override
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_hasFormalsInferred) return;
    _introductory.inferFormalTypes(libraryBuilder, declarationBuilder, this,
        hierarchy, _delayedDefaultValueCloners);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.inferFormalTypes(libraryBuilder, declarationBuilder, this,
          hierarchy, _delayedDefaultValueCloners);
    }
    _hasFormalsInferred = true;
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    _introductory.addSuperParameterDefaultValueCloners(
        libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.addSuperParameterDefaultValueCloners(
          libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
    }
  }
}

class SyntheticSourceConstructorBuilder extends MemberBuilderImpl
    with SourceMemberBuilderMixin
    implements SourceConstructorBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final SourceClassBuilder classBuilder;

  final Constructor _constructor;
  final Procedure? _constructorTearOff;

  /// The constructor from which this synthesized constructor is defined.
  ///
  /// This defines the parameter structure and the default values of this
  /// constructor.
  ///
  /// The [_immediatelyDefiningConstructor] might itself a synthesized
  /// constructor and [_effectivelyDefiningConstructor] can be used to find
  /// the constructor that effectively defines this constructor.
  MemberBuilder? _immediatelyDefiningConstructor;
  DelayedDefaultValueCloner? _delayedDefaultValueCloner;
  TypeDependency? _typeDependency;

  SyntheticSourceConstructorBuilder(this.libraryBuilder, this.classBuilder,
      Constructor constructor, Procedure? constructorTearOff,
      {MemberBuilder? definingConstructor,
      DelayedDefaultValueCloner? delayedDefaultValueCloner,
      TypeDependency? typeDependency})
      : _immediatelyDefiningConstructor = definingConstructor,
        _delayedDefaultValueCloner = delayedDefaultValueCloner,
        _typeDependency = typeDependency,
        _constructor = constructor,
        _constructorTearOff = constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => _constructor.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _constructor.fileUri;

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_constructor.reference];

  @override
  String get name => _constructor.name.text;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _constructor.name;

  @override
  bool get isConstructor => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => _constructor.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthetic => _constructor.isSynthetic;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRegularMethod => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isGetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isOperator => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFactory => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  Builder get getable => this;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  FunctionNode get function => _constructor.function;

  @override
  Member get readTarget => _constructorTearOff ?? _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_constructorTearOff ?? _constructor).reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  Constructor get invokeTarget => _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _constructor.reference;

  @override
  bool get isConst => _constructor.isConst;

  @override
  DeclarationBuilder get declarationBuilder => classBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRedirecting {
    for (Initializer initializer in _constructor.initializers) {
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_immediatelyDefiningConstructor is SourceConstructorBuilder) {
      (_immediatelyDefiningConstructor as SourceConstructorBuilder)
          .inferFormalTypes(hierarchy);
    }
    if (_typeDependency != null) {
      _typeDependency!.copyInferred();
      _typeDependency = null;
    }
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_immediatelyDefiningConstructor != null) {
      // Ensure that default value expressions have been created for [_origin].
      // If [_origin] is from a source library, we need to build the default
      // values and initializers first.
      MemberBuilder origin = _immediatelyDefiningConstructor!;
      if (origin is SourceConstructorBuilder) {
        origin.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
      addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
      _immediatelyDefiningConstructor = null;
    }
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    MemberBuilder? origin = _immediatelyDefiningConstructor;
    if (origin is SourceConstructorBuilder) {
      origin.addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    }
    if (_delayedDefaultValueCloner != null) {
      // For constant constructors default values are computed and cloned part
      // of the outline expression and we there set `isOutlineNode` to `true`
      // below.
      //
      // For non-constant constructors default values are cloned as part of the
      // full compilation using `KernelTarget._delayedDefaultValueCloners`.
      delayedDefaultValueCloners
          .add(_delayedDefaultValueCloner!..isOutlineNode = true);
      _delayedDefaultValueCloner = null;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    assert(false, "Unexpected call to $runtimeType.computeDefaultType");
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {}
}

class ExtensionTypeInitializerToStatementConverter
    implements InitializerVisitor<void> {
  VariableDeclaration thisVariable;
  final List<Statement> statements;

  ExtensionTypeInitializerToStatementConverter(
      this.statements, this.thisVariable);

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    if (node is ExtensionTypeRedirectingInitializer) {
      statements.add(new ExpressionStatement(
          new VariableSet(
              thisVariable,
              new StaticInvocation(node.target, node.arguments)
                ..fileOffset = node.fileOffset)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset);
      return;
    } else if (node is ExtensionTypeRepresentationFieldInitializer) {
      thisVariable
        ..initializer = (node.value..parent = thisVariable)
        ..fileOffset = node.fileOffset;
      return;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFieldInitializer(FieldInitializer node) {
    thisVariable
      ..initializer = (node.value..parent = thisVariable)
      ..fileOffset = node.fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitInvalidInitializer(InvalidInitializer node) {
    statements.add(new ExpressionStatement(
        new InvalidExpression(null)..fileOffset = node.fileOffset)
      ..fileOffset);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    statements.add(node.variable);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperInitializer(SuperInitializer node) {
    // TODO(johnniwinther): Report error for this case.
  }
}

class InferableConstructor implements InferableMember {
  @override
  final Member member;

  final SourceConstructorBuilder _builder;

  InferableConstructor(this.member, this._builder);

  @override
  void inferMemberTypes(ClassHierarchyBase classHierarchy) {
    _builder.inferFormalTypes(classHierarchy);
  }

  @override
  void reportCyclicDependency() {
    // There is a cyclic dependency where inferring the types of the
    // initializing formals of a constructor required us to infer the
    // corresponding field type which required us to know the type of the
    // constructor.
    String name = _builder.declarationBuilder.name;
    if (_builder.name.isNotEmpty) {
      // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
      // instead. However, `inferrer.helper` may be null.
      name += ".${_builder.name}";
    }
    _builder.libraryBuilder.addProblem(
        templateCantInferTypeDueToCircularity.withArguments(name),
        _builder.fileOffset,
        name.length,
        _builder.fileUri);
  }
}
