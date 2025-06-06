// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/type_algebra.dart';

import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/library_builder.dart';
import '../../builder/type_builder.dart';
import '../../codes/cfe_codes.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../testing/id_testing_utils.dart' show typeToText;
import '../../type_inference/type_schema.dart' show UnknownType;
import 'hierarchy_builder.dart';
import 'mixin_inferrer.dart';

abstract class HierarchyNodeBuilder {
  final ClassHierarchyBuilder _hierarchy;

  HierarchyNodeBuilder(this._hierarchy);

  LibraryBuilder get _libraryBuilder;

  String get _name;

  int get _fileOffset;

  Uri get _fileUri;

  Supertype _resolveSupertypeConflict(Supertype type, Supertype superclass) {
    Supertype? merge = nnbdTopMergeSupertype(
        _hierarchy.coreTypes,
        normSupertype(_hierarchy.coreTypes, superclass),
        normSupertype(_hierarchy.coreTypes, type));
    if (merge != null) {
      return merge;
    }
    LibraryBuilder libraryBuilder = _libraryBuilder;
    if (libraryBuilder is SourceLibraryBuilder) {
      libraryBuilder.addProblem(
          templateAmbiguousSupertypes.withArguments(
              _name, superclass.asInterfaceType, type.asInterfaceType),
          _fileOffset,
          noLength,
          _fileUri);
    }
    return superclass;
  }

  List<Supertype> _substSupertypes(
      TypeDeclarationType supertype, List<Supertype> supertypes) {
    List<TypeParameter> typeParameters =
        supertype.typeDeclaration.typeParameters;
    if (typeParameters.isEmpty) {
      return supertypes;
    }
    Map<TypeParameter, DartType> map = <TypeParameter, DartType>{};
    List<DartType> arguments = supertype.typeArguments;
    for (int i = 0; i < typeParameters.length; i++) {
      map[typeParameters[i]] = arguments[i];
    }
    Substitution substitution = Substitution.fromMap(map);
    List<Supertype>? result;
    for (int i = 0; i < supertypes.length; i++) {
      Supertype supertype = supertypes[i];
      Supertype substituted = substitution.substituteSupertype(supertype);
      if (supertype != substituted) {
        result ??= supertypes.toList();
        result[i] = substituted;
      }
    }
    return result ?? supertypes;
  }

  /// The class Function from dart:core is supposed to be ignored when used as
  /// an interface.
  List<TypeBuilder>? _ignoreFunction(List<TypeBuilder>? interfaces) {
    if (interfaces == null) return null;
    for (int i = 0; i < interfaces!.length; i++) {
      ClassBuilder? classBuilder = getClass(interfaces[i]);
      if (classBuilder != null &&
          classBuilder.cls == _hierarchy.functionClass) {
        if (interfaces.length == 1) {
          return null;
        } else {
          interfaces = interfaces.toList();
          interfaces.removeAt(i);
          return _ignoreFunction(interfaces);
        }
      }
    }
    return interfaces;
  }
}

class ClassHierarchyNodeBuilder extends HierarchyNodeBuilder {
  final ClassBuilder _classBuilder;

  ClassHierarchyNodeBuilder(super.hierarchy, this._classBuilder);

  ClassBuilder get _objectClass => _hierarchy.objectClassBuilder;

  @override
  LibraryBuilder get _libraryBuilder => _classBuilder.libraryBuilder;

  @override
  String get _name => _classBuilder.name;

  @override
  int get _fileOffset => _classBuilder.fileOffset;

  @override
  Uri get _fileUri => _classBuilder.fileUri;

  ClassHierarchyNode build() {
    ClassHierarchyNode? supernode;
    if (_objectClass != _classBuilder) {
      ClassBuilder? superClassBuilder =
          getClass(_classBuilder.supertypeBuilder!);
      supernode =
          _hierarchy.getNodeFromClassBuilder(superClassBuilder ?? _objectClass);
    }

    List<Supertype> superclasses;
    List<Supertype> interfacesList;
    int maxInheritancePath;

    ClassHierarchyNode? mixedInNode;
    List<ClassHierarchyNode>? interfaceNodes;

    if (_classBuilder.isMixinApplication) {
      mixedInNode = _inferMixinApplication();
    }

    if (supernode == null) {
      // This should be Object.
      superclasses = new List<Supertype>.filled(0, dummySupertype);
      interfacesList = new List<Supertype>.filled(0, dummySupertype);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses = new List<Supertype>.filled(
          supernode.superclasses.length + 1, dummySupertype);
      Supertype? supertype = _classBuilder.supertypeBuilder!.buildSupertype(
          _classBuilder.libraryBuilder, TypeUse.classExtendsType);
      if (supertype == null) {
        // If the superclass is not an interface type we use Object instead.
        // A similar normalization is performed on [supernode] above.
        supertype =
            new Supertype(_hierarchy.coreTypes.objectClass, const <DartType>[]);
      }
      InterfaceType superTypeAsInterfaceType = supertype.asInterfaceType;
      superclasses.setRange(0, superclasses.length - 1,
          _substSupertypes(superTypeAsInterfaceType, supernode.superclasses));
      superclasses[superclasses.length - 1] = supertype;

      List<TypeBuilder>? directInterfaceBuilders =
          _ignoreFunction(_classBuilder.interfaceBuilders);
      if (_classBuilder.isMixinApplication) {
        if (directInterfaceBuilders == null) {
          directInterfaceBuilders = <TypeBuilder>[
            _classBuilder.mixedInTypeBuilder!
          ];
        } else {
          directInterfaceBuilders = <TypeBuilder>[
            _classBuilder.mixedInTypeBuilder!
          ]..addAll(directInterfaceBuilders);
        }
      }

      List<Supertype> superclassInterfaces = supernode.interfaces;
      if (superclassInterfaces.isNotEmpty) {
        superclassInterfaces =
            _substSupertypes(superTypeAsInterfaceType, superclassInterfaces);
      }

      if (directInterfaceBuilders != null) {
        Map<Class, Supertype> interfaces = {};
        if (superclassInterfaces.isNotEmpty) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            _addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }

        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          Supertype? directInterface = directInterfaceBuilders[i]
              .buildSupertype(
                  _classBuilder.libraryBuilder,
                  _classBuilder.isMixinApplication
                      ? TypeUse.classWithType
                      : TypeUse.classImplementsType);
          if (directInterface != null) {
            _addInterface(interfaces, superclasses, directInterface);
            ClassHierarchyNode interfaceNode =
                _hierarchy.getNodeFromClass(directInterface.classNode);
            (interfaceNodes ??= []).add(interfaceNode);

            if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
              maxInheritancePath = interfaceNode.maxInheritancePath + 1;
            }

            InterfaceType directInterfaceAsInterfaceType =
                directInterface.asInterfaceType;
            List<Supertype> types = _substSupertypes(
                directInterfaceAsInterfaceType, interfaceNode.superclasses);
            for (int i = 0; i < types.length; i++) {
              _addInterface(interfaces, superclasses, types[i]);
            }
            if (interfaceNode.interfaces.isNotEmpty) {
              List<Supertype> types = _substSupertypes(
                  directInterfaceAsInterfaceType, interfaceNode.interfaces);
              for (int i = 0; i < types.length; i++) {
                _addInterface(interfaces, superclasses, types[i]);
              }
            }
          }
        }
        interfacesList = interfaces.values.toList();
      } else {
        interfacesList = superclassInterfaces;
      }
    }

    return new ClassHierarchyNode(_classBuilder, supernode, mixedInNode,
        interfaceNodes, superclasses, interfacesList, maxInheritancePath);
  }

  void _addInterface(Map<Class, Supertype> interfaces,
      List<Supertype> superclasses, Supertype type) {
    ClassHierarchyNode node = _hierarchy.getNodeFromClass(type.classNode);
    int depth = node.depth;
    int myDepth = superclasses.length;
    Supertype? superclass = depth < myDepth ? superclasses[depth] : null;
    if (superclass != null && superclass.classNode == type.classNode) {
      // This is a potential conflict.
      superclasses[depth] = _resolveSupertypeConflict(type, superclass);
      return;
    } else {
      Supertype? interface = interfaces[type.classNode];
      if (interface != null) {
        // This is a potential conflict.
        interfaces[type.classNode] = _resolveSupertypeConflict(type, interface);
        return;
      }
    }
    interfaces[type.classNode] = type;
  }

  ClassHierarchyNode? _inferMixinApplication() {
    Class cls = _classBuilder.cls;
    Supertype? mixedInSupertype = cls.mixedInType;
    if (mixedInSupertype == null) return null;
    ClassHierarchyNode? mixinNode =
        _hierarchy.getNodeFromClass(mixedInSupertype.classNode);
    List<DartType> typeArguments = mixedInSupertype.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) {
      return mixinNode;
    }
    ClassBuilder classBuilder = _classBuilder;
    if (classBuilder is SourceClassBuilder) {
      new BuilderMixinInferrer(classBuilder, _hierarchy,
              mixedInSupertype.classNode.typeParameters)
          .infer(cls);
      classBuilder.setInferredMixedInTypeArguments(
          new List<TypeBuilder>.generate(typeArguments.length,
              (int i) => _hierarchy.loader.computeTypeBuilder(typeArguments[i]),
              growable: false));
    }
    return mixinNode;
  }
}

class ClassHierarchyNode {
  /// The class corresponding to this hierarchy node.
  final ClassBuilder classBuilder;

  /// The [ClassHierarchyNode] for the direct super class of [classBuilder], or
  /// `null` if this is `Object`.
  final ClassHierarchyNode? directSuperClassNode;

  /// The [ClassHierarchyNode] for the mixed in class, if [classBuilder] is a
  /// mixin application, or `null` otherwise;
  final ClassHierarchyNode? mixedInNode;

  /// The [ClassHierarchyNode]s for the direct super interfaces of
  /// [classBuilder].
  final List<ClassHierarchyNode>? directInterfaceNodes;

  /// All superclasses of [classBuilder] excluding itself. The classes are
  /// sorted by depth from the root (Object) in ascending order.
  final List<Supertype> superclasses;

  /// The list of all classes implemented by [classBuilder] and its supertypes
  /// excluding any classes from [superclasses].
  final List<Supertype> interfaces;

  /// The longest inheritance path from [classBuilder] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  ClassHierarchyNode(
      this.classBuilder,
      this.directSuperClassNode,
      this.mixedInNode,
      this.directInterfaceNodes,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath);

  /// Returns `true` if [classBuilder] is a mixin application.
  ///
  /// If `true`, [mixedInNode] is non-null.
  bool get isMixinApplication => mixedInNode != null;

  // Coverage-ignore(suite): Not run.
  /// Returns a list of all supertypes of [classBuilder], including this node.
  List<ClassHierarchyNode> computeAllSuperNodes(
      ClassHierarchyBuilder hierarchy) {
    List<ClassHierarchyNode> result = [];
    for (int i = 0; i < superclasses.length; i++) {
      Supertype type = superclasses[i];
      result.add(hierarchy.getNodeFromClass(type.classNode));
    }
    for (int i = 0; i < interfaces.length; i++) {
      Supertype type = interfaces[i];
      result.add(hierarchy.getNodeFromClass(type.classNode));
    }
    result.add(this);
    return result;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb
      ..write(classBuilder.fullNameForErrors)
      ..writeln(":");
    if (maxInheritancePath != this.depth) {
      sb
        ..write("  Longest path to Object: ")
        ..writeln(maxInheritancePath);
    }
    sb..writeln("  superclasses:");
    int depth = 0;
    for (Supertype superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      sb.write(typeToText(superclass.asInterfaceType));
      sb.writeln();
      depth++;
    }
    if (interfaces.isNotEmpty) {
      sb.write("  interfaces:");
      bool first = true;
      for (Supertype i in interfaces) {
        if (!first) sb.write(",");
        sb.write(" ");
        sb.write(typeToText(i.asInterfaceType));
        first = false;
      }
      sb.writeln();
    }
    return "$sb";
  }

  // Coverage-ignore(suite): Not run.
  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

class ExtensionTypeHierarchyNodeBuilder extends HierarchyNodeBuilder {
  final ExtensionTypeDeclarationBuilder _extensionTypeBuilder;

  ExtensionTypeHierarchyNodeBuilder(
      super._hierarchy, this._extensionTypeBuilder);

  @override
  LibraryBuilder get _libraryBuilder => _extensionTypeBuilder.libraryBuilder;

  @override
  String get _name => _extensionTypeBuilder.name;

  @override
  int get _fileOffset => _extensionTypeBuilder.fileOffset;

  @override
  Uri get _fileUri => _extensionTypeBuilder.fileUri;

  ExtensionTypeHierarchyNode build() {
    Map<Class, Supertype> superclasses = {};
    Map<ExtensionTypeDeclaration, ExtensionType> superExtensionTypes = {};
    List<ClassHierarchyNode>? superclassNodes;
    List<ExtensionTypeHierarchyNode>? superExtensionTypeNodes;
    int maxInheritancePath = 1;

    List<TypeBuilder>? directInterfaceBuilders =
        _ignoreFunction(_extensionTypeBuilder.interfaceBuilders);
    if (directInterfaceBuilders != null) {
      for (int i = 0; i < directInterfaceBuilders.length; i++) {
        DartType directInterface = directInterfaceBuilders[i].build(
            _extensionTypeBuilder.libraryBuilder,
            TypeUse.extensionTypeImplementsType);
        if (directInterface is InterfaceType) {
          Supertype supertype = new Supertype.byReference(
              directInterface.classReference, directInterface.typeArguments);
          _addSuperClass(superclasses, supertype);
          ClassHierarchyNode interfaceNode =
              _hierarchy.getNodeFromClass(directInterface.classNode);
          (superclassNodes ??= []).add(interfaceNode);

          if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
            maxInheritancePath = interfaceNode.maxInheritancePath + 1;
          }

          InterfaceType superTypeAsInterfaceType = supertype.asInterfaceType;
          List<Supertype> types = _substSupertypes(
              superTypeAsInterfaceType, interfaceNode.superclasses);
          for (int i = 0; i < types.length; i++) {
            _addSuperClass(superclasses, types[i]);
          }
          if (interfaceNode.interfaces.isNotEmpty) {
            List<Supertype> types = _substSupertypes(
                superTypeAsInterfaceType, interfaceNode.interfaces);
            for (int i = 0; i < types.length; i++) {
              _addSuperClass(superclasses, types[i]);
            }
          }
        } else if (directInterface is ExtensionType) {
          _addSuperExtensionType(superExtensionTypes, directInterface);
          ExtensionTypeHierarchyNode interfaceNode =
              _hierarchy.getNodeFromExtensionType(
                  directInterface.extensionTypeDeclaration);
          (superExtensionTypeNodes ??= []).add(interfaceNode);

          if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
            maxInheritancePath = interfaceNode.maxInheritancePath + 1;
          }

          List<ExtensionType> types = _substSuperExtensionTypes(
              directInterface, interfaceNode.superExtensionTypes);
          for (int i = 0; i < types.length; i++) {
            _addSuperExtensionType(superExtensionTypes, types[i]);
          }
          if (interfaceNode.superclasses.isNotEmpty) {
            List<Supertype> types =
                _substSupertypes(directInterface, interfaceNode.superclasses);
            for (int i = 0; i < types.length; i++) {
              _addSuperClass(superclasses, types[i]);
            }
          }
        }
      }
    }

    return new ExtensionTypeHierarchyNode(
        _extensionTypeBuilder,
        superclasses.values.toList(),
        superExtensionTypes.values.toList(),
        superclassNodes,
        superExtensionTypeNodes,
        maxInheritancePath);
  }

  void _addSuperClass(Map<Class, Supertype> superClasses, Supertype type) {
    Supertype? interface = superClasses[type.classNode];
    if (interface != null) {
      // This is a potential conflict.
      superClasses[type.classNode] = _resolveSupertypeConflict(type, interface);
      return;
    }
    superClasses[type.classNode] = type;
  }

  ExtensionType _resolveSuperExtensionTypeConflict(
      ExtensionType type, ExtensionType superclass) {
    DartType? merge = nnbdTopMerge(
        _hierarchy.coreTypes,
        norm(_hierarchy.coreTypes, superclass),
        norm(_hierarchy.coreTypes, type));
    if (merge != null) {
      return merge as ExtensionType;
    }
    LibraryBuilder libraryBuilder = _libraryBuilder;
    if (libraryBuilder is SourceLibraryBuilder) {
      libraryBuilder.addProblem(
          templateAmbiguousSupertypes.withArguments(_name, superclass, type),
          _fileOffset,
          noLength,
          _fileUri);
    }
    return superclass;
  }

  void _addSuperExtensionType(
      Map<ExtensionTypeDeclaration, ExtensionType> interfaces,
      ExtensionType type) {
    ExtensionType? interface = interfaces[type.extensionTypeDeclaration];
    if (interface != null) {
      // This is a potential conflict.
      interfaces[type.extensionTypeDeclaration] =
          _resolveSuperExtensionTypeConflict(type, interface);
      return;
    }
    interfaces[type.extensionTypeDeclaration] = type;
  }

  List<ExtensionType> _substSuperExtensionTypes(
      ExtensionType superExtensionType,
      List<ExtensionType> superExtensionTypes) {
    List<TypeParameter> typeParameters =
        superExtensionType.extensionTypeDeclaration.typeParameters;
    if (typeParameters.isEmpty) {
      return superExtensionTypes;
    }
    Map<TypeParameter, DartType> map = <TypeParameter, DartType>{};
    List<DartType> arguments = superExtensionType.typeArguments;
    for (int i = 0; i < typeParameters.length; i++) {
      map[typeParameters[i]] = arguments[i];
    }
    Substitution substitution = Substitution.fromMap(map);
    List<ExtensionType>? result;
    for (int i = 0; i < superExtensionTypes.length; i++) {
      ExtensionType supertype = superExtensionTypes[i];
      ExtensionType substituted =
          substitution.substituteType(supertype) as ExtensionType;
      if (supertype != substituted) {
        result ??= superExtensionTypes.toList();
        result[i] = substituted;
      }
    }
    return result ?? superExtensionTypes;
  }
}

class ExtensionTypeHierarchyNode {
  /// The extension type corresponding to this hierarchy node.
  final ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder;

  /// The list of all classes implemented by [extensionTypeDeclarationBuilder]
  /// and its superclasses.
  final List<Supertype> superclasses;

  /// The list of all extension types implemented by
  /// [extensionTypeDeclarationBuilder] and its super extension types.
  final List<ExtensionType> superExtensionTypes;

  /// The [ClassHierarchyNode]s for the direct superclasses of
  /// [extensionTypeDeclarationBuilder].
  final List<ClassHierarchyNode>? directSuperclassNodes;

  /// The [ExtensionTypeHierarchyNode]s for the direct super extension types of
  /// [extensionTypeDeclarationBuilder].
  final List<ExtensionTypeHierarchyNode>? directSuperExtensionTypeNodes;

  /// The longest inheritance path from [extensionTypeDeclarationBuilder] to
  /// `Object`.
  final int maxInheritancePath;

  ExtensionTypeHierarchyNode(
      this.extensionTypeDeclarationBuilder,
      this.superclasses,
      this.superExtensionTypes,
      this.directSuperclassNodes,
      this.directSuperExtensionTypeNodes,
      this.maxInheritancePath);
}

ClassBuilder? getClass(TypeBuilder type) {
  Builder? declaration = type.computeUnaliasedDeclaration(isUsedAsClass: false);
  return declaration is ClassBuilder ? declaration : null;
}
