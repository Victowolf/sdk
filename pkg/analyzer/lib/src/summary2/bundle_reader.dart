// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/element_flags.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:pub_semver/pub_semver.dart';

class BundleReader {
  final SummaryDataReader _reader;
  final Map<Uri, Uint8List> _unitsInformativeBytes;
  final InfoDeclarationStore _infoDeclarationStore;

  final Map<Uri, LibraryReader> libraryMap = {};

  BundleReader({
    required LinkedElementFactory elementFactory,
    required Uint8List resolutionBytes,
    Map<Uri, Uint8List> unitsInformativeBytes = const {},
    required InfoDeclarationStore infoDeclarationStore,
    required Map<Uri, LibraryManifest> libraryManifests,
  })  : _reader = SummaryDataReader(resolutionBytes),
        _unitsInformativeBytes = unitsInformativeBytes,
        _infoDeclarationStore = infoDeclarationStore {
    const bytesOfU32 = 4;
    const countOfU32 = 4;
    _reader.offset = _reader.bytes.length - bytesOfU32 * countOfU32;
    var baseResolutionOffset = _reader.readUInt32();
    var librariesOffset = _reader.readUInt32();
    var referencesOffset = _reader.readUInt32();
    var stringsOffset = _reader.readUInt32();
    _reader.createStringTable(stringsOffset);

    var referenceReader = _ReferenceReader(
      elementFactory,
      _reader,
      referencesOffset,
    );

    _reader.offset = librariesOffset;
    var libraryHeaderList = _reader.readTypedList(() {
      return _LibraryHeader(
        uri: uriCache.parse(_reader.readStringReference()),
        offset: _reader.readUInt30(),
        classMembersLengths: _reader.readUInt30List(),
      );
    });

    for (var libraryHeader in libraryHeaderList) {
      var uri = libraryHeader.uri;
      var reference = elementFactory.rootReference.getChild('$uri');
      libraryMap[uri] = LibraryReader._(
        elementFactory: elementFactory,
        reader: _reader,
        uri: uri,
        unitsInformativeBytes: _unitsInformativeBytes,
        baseResolutionOffset: baseResolutionOffset,
        referenceReader: referenceReader,
        reference: reference,
        offset: libraryHeader.offset,
        classMembersLengths: libraryHeader.classMembersLengths,
        infoDeclarationStore: _infoDeclarationStore,
        manifest: libraryManifests[uri],
      );
    }
  }
}

class ClassElementLinkedData extends ElementLinkedData<ClassElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;
  void Function()? _readMembers;
  void Function()? applyInformativeDataToMembers;

  ClassElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void readMembers(covariant ClassElementImpl fragment) {
    // Read members of all fragments, in order.
    // So we always read a method augmentation after its target.
    for (var fragment in fragment.element.fragments) {
      var linkedData = fragment.linkedData;
      if (linkedData is ClassElementLinkedData) {
        linkedData._readSingleFragmentMembers(fragment);
      }
    }
  }

  @override
  void _clearLinkedDataOnRead(ClassElementImpl element) {
    // Don't clear yet, we use it to read members on demand.
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();

    applyConstantOffsets?.perform();
  }

  void _readSingleFragmentMembers(ClassElementImpl element) {
    // We might read class members before other properties.
    element.linkedData?.read(element);
    element.linkedData = null;

    if (element.isMixinApplication) {
      element.constructors;
    } else {
      _readMembers?.call();
      _readMembers = null;

      applyInformativeDataToMembers?.call();
      applyInformativeDataToMembers = null;
    }
  }
}

class CompilationUnitElementLinkedData
    extends ElementLinkedData<CompilationUnitElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  CompilationUnitElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(CompilationUnitElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    for (var import in element.libraryImports) {
      import.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      var uri = import.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var export in element.libraryExports) {
      export.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      var uri = export.uri;
      if (uri is DirectiveUriWithLibraryImpl) {
        uri.library = reader.libraryOfUri(uri.source.uri);
      }
    }

    for (var part in element.parts) {
      part.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
    }

    applyConstantOffsets?.perform();
  }
}

class ConstructorElementLinkedData
    extends ElementLinkedData<ConstructorElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ConstructorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ConstructorElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    reader._addFormalParameters(element.parameters);
    _readFormalParameters(reader, element.parameters);
    element.superConstructor = reader.readElement() as ConstructorElementMixin?;
    element.redirectedConstructor =
        reader.readElement() as ConstructorElementMixin?;
    element.constantInitializers = reader._readNodeList();
    applyConstantOffsets?.perform();
  }
}

/// Lazy reader of resolution information.
abstract class ElementLinkedData<E extends ElementImpl> {
  final Reference reference;
  final LibraryReader _libraryReader;
  final CompilationUnitElementImpl unitElement;

  /// When this object is created, this offset is the offset of the resolution
  /// information in the [_libraryReader]. After reading is done, this offset
  /// is set to `-1`.
  int _offset;

  ElementLinkedData(
      this.reference, LibraryReader libraryReader, this.unitElement, int offset)
      : _libraryReader = libraryReader,
        _offset = offset;

  void read(ElementImpl element) {
    _clearLinkedDataOnRead(element as E);
    if (_offset == -1) {
      return;
    }

    var dataReader = _libraryReader._reader.fork(_offset);
    _offset = -1;

    var reader = ResolutionReader(
      _libraryReader._elementFactory,
      _libraryReader._referenceReader,
      dataReader,
    );

    _read(element, reader);
  }

  /// Ensure that all members of the [element] are available. This includes
  /// being able to ask them for example using [ClassElement2.methods2], and
  /// as well access them through their [Reference]s. For a class declaration
  /// this means reading them, for a named mixin application this means
  /// computing constructors.
  void readMembers(InstanceElementImpl element) {}

  void _addEnclosingElementTypeParameters(
    ResolutionReader reader,
    ElementImpl element,
  ) {
    var enclosing = element.enclosingElement3;
    if (enclosing is InstanceElementImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is CompilationUnitElementImpl) {
      // Nothing.
    } else if (enclosing is EnumElementImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is ExtensionElementImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else if (enclosing is MixinElementImpl) {
      reader._addTypeParameters(enclosing.typeParameters);
    } else {
      throw UnimplementedError('${enclosing.runtimeType}');
    }
  }

  void _clearLinkedDataOnRead(E element);

  void _read(E element, ResolutionReader reader);

  void _readFormalParameters(
    ResolutionReader reader,
    List<ParameterElementImpl> parameters,
  ) {
    for (var parameter in parameters) {
      parameter.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      _readTypeParameters(reader, parameter.typeParameters);
      _readFormalParameters(reader, parameter.parameters);
      parameter.type = reader.readRequiredType();
      if (parameter is ConstVariableElement) {
        var defaultParameter = parameter as ConstVariableElement;
        var initializer = reader._readOptionalExpression();
        if (initializer != null) {
          defaultParameter.constantInitializer = initializer;
        }
      }
      if (parameter is FieldFormalParameterElementImpl) {
        parameter.field = reader.readElement() as FieldElementImpl?;
      }
    }
  }

  void _readTypeParameters(
    ResolutionReader reader,
    List<TypeParameterElementImpl> typeParameters,
  ) {
    reader._addTypeParameters(typeParameters);
    for (var typeParameter in typeParameters) {
      typeParameter.metadata = reader._readAnnotationList(
        unitElement: unitElement,
      );
      typeParameter.bound = reader.readType();
      typeParameter.defaultType = reader.readType();
    }
  }
}

class EnumElementLinkedData extends ElementLinkedData<EnumElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  EnumElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(EnumElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.supertype = reader._readOptionalInterfaceType();
    element.mixins = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();
    applyConstantOffsets?.perform();
  }
}

class ExtensionElementLinkedData
    extends ElementLinkedData<ExtensionElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ExtensionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ExtensionElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    var extendedType = reader.readRequiredType();
    var augmented = element.augmentedInternal;
    augmented.extendedType = extendedType;

    applyConstantOffsets?.perform();
  }
}

class ExtensionTypeElementLinkedData
    extends ElementLinkedData<ExtensionTypeElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  ExtensionTypeElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(ExtensionTypeElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.interfaces = reader._readInterfaceTypeList();
    element.typeErasure = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class FieldElementLinkedData extends ElementLinkedData<FieldElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FieldElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(FieldElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    element.type = reader.readRequiredType();

    if (element is ConstFieldElementImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(element, initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class FunctionElementLinkedData extends ElementLinkedData<FunctionElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  FunctionElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(FunctionElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);
    applyConstantOffsets?.perform();
  }
}

/// Not an [ElementLinkedData], just a bundle with data.
class LibraryAugmentationElementLinkedData {
  final int offset;
  ApplyConstantOffsets? applyConstantOffsets;

  LibraryAugmentationElementLinkedData({
    required this.offset,
  });
}

class LibraryElementLinkedData extends ElementLinkedData<LibraryElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  /// When we are applying offsets to a library, we want to lock it.
  bool _isLocked = false;

  LibraryElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  LinkedElementFactory get elementFactory {
    return _libraryReader._elementFactory;
  }

  void lock() {
    assert(!_isLocked);
    _isLocked = true;
  }

  @override
  void read(ElementImpl element) {
    if (!_isLocked) {
      super.read(element);
    }
  }

  void unlock() {
    assert(_isLocked);
    _isLocked = false;
  }

  @override
  void _clearLinkedDataOnRead(LibraryElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );

    element.entryPoint2 = reader.readElement2() as TopLevelFunctionElementImpl?;

    element.fieldNameNonPromotabilityInfo =
        _readFieldNameNonPromotabilityInfo(reader);

    element.exportNamespace = elementFactory.buildExportNamespace(
      element.source.uri,
      element.exportedReferences,
    );

    applyConstantOffsets?.perform();
  }

  Map<String, FieldNameNonPromotabilityInfo>?
      _readFieldNameNonPromotabilityInfo(ResolutionReader reader) {
    return reader.readOptionalObject(() {
      return reader.readMap(
        readKey: () => reader.readStringReference(),
        readValue: () {
          return FieldNameNonPromotabilityInfo(
            conflictingFields: reader.readElementList2(),
            conflictingGetters: reader.readElementList2(),
            conflictingNsmClasses: reader.readElementList2(),
          );
        },
      );
    });
  }
}

class LibraryReader {
  final LinkedElementFactory _elementFactory;
  final SummaryDataReader _reader;
  final Uri uri;
  final Map<Uri, Uint8List> _unitsInformativeBytes;
  final int _baseResolutionOffset;
  final _ReferenceReader _referenceReader;
  final Reference _reference;
  final int _offset;
  final InfoDeclarationStore _deserializedDataStore;
  final LibraryManifest? manifest;

  final Uint32List _classMembersLengths;
  int _classMembersLengthsIndex = 0;

  late final LibraryElementImpl _libraryElement;

  LibraryReader._({
    required LinkedElementFactory elementFactory,
    required SummaryDataReader reader,
    required this.uri,
    required Map<Uri, Uint8List> unitsInformativeBytes,
    required int baseResolutionOffset,
    required _ReferenceReader referenceReader,
    required Reference reference,
    required int offset,
    required Uint32List classMembersLengths,
    required InfoDeclarationStore infoDeclarationStore,
    required this.manifest,
  })  : _elementFactory = elementFactory,
        _reader = reader,
        _unitsInformativeBytes = unitsInformativeBytes,
        _baseResolutionOffset = baseResolutionOffset,
        _referenceReader = referenceReader,
        _reference = reference,
        _offset = offset,
        _classMembersLengths = classMembersLengths,
        _deserializedDataStore = infoDeclarationStore;

  LibraryElementImpl readElement({required Source librarySource}) {
    var analysisContext = _elementFactory.analysisContext;
    var analysisSession = _elementFactory.analysisSession;

    _reader.offset = _offset;

    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/51855
    // This should not be needed.
    // But I have a suspicion that we attempt to read the library twice.
    _classMembersLengthsIndex = 0;

    // Read enough data to create the library.
    var name = _reader.readStringReference();
    var featureSet = _readFeatureSet();

    // Create the library, link to the reference.
    _libraryElement = LibraryElementImpl(
        analysisContext, analysisSession, name, -1, 0, featureSet);
    _reference.element = _libraryElement;
    _libraryElement.reference = _reference;

    // Read the rest of non-resolution data for the library.
    LibraryElementFlags.read(_reader, _libraryElement);
    _libraryElement.languageVersion = _readLanguageVersion();

    _libraryElement.exportedReferences = _reader.readTypedList(
      _readExportedReference,
    );

    _libraryElement.nameUnion = ElementNameUnion.read(
      _reader.readUInt30List(),
    );

    _libraryElement.manifest = manifest;

    _libraryElement.loadLibraryProvider = LoadLibraryFunctionProvider(
      fragmentReference: _readReference(),
      elementReference: _readReference(),
    );

    // Read the library units.
    _libraryElement.definingCompilationUnit = _readUnitElement(
      containerUnit: null,
      unitSource: librarySource,
    );

    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    _libraryElement.linkedData = LibraryElementLinkedData(
      reference: _reference,
      libraryReader: this,
      unitElement: _libraryElement.definingCompilationUnit,
      offset: resolutionOffset,
    );

    _declareDartCoreDynamicNever();

    InformativeDataApplier(
            _elementFactory, _unitsInformativeBytes, _deserializedDataStore)
        .applyTo(_libraryElement);

    return _libraryElement;
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (_reference.name == 'dart:core') {
      _reference.getChild('dynamic').element = DynamicElementImpl.instance;
      _reference.getChild('Never').element = NeverElementImpl.instance;
    }
  }

  ClassElementImpl _readClassElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();
    var name = fragmentName ?? '';

    var fragment = ClassElementImpl(name, -1);
    fragment.name2 = fragmentName;

    if (reference2.element2 case ClassElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ClassElementImpl2(reference2, fragment);
      _libraryElement.classes.add(element);
    }

    var linkedData = ClassElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    ClassElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    if (!fragment.isMixinApplication) {
      var membersOffset = _reader.offset;
      linkedData._readMembers = () {
        _reader.offset = membersOffset;
        _readClassElementMembers(fragment, reference);
      };
      _reader.offset += _classMembersLengths[_classMembersLengthsIndex++];
    }

    return fragment;
  }

  void _readClassElementMembers(
    ClassElementImpl fragment,
    Reference reference,
  ) {
    var unitElement = fragment.enclosingElement3;

    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElementImpl>[];
    _readFields(unitElement, fragment, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, fragment, reference, accessors, fields, '@field');
    fragment.fields = fields.toFixedList();
    fragment.accessors = accessors.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);
  }

  void _readClasses(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.classes = _reader.readTypedList(() {
      return _readClassElement(unitElement, unitReference);
    });
  }

  List<ConstructorElementImpl> _readConstructors(
    CompilationUnitElementImpl unitElement,
    InterfaceElementImpl classElement,
    Reference classReference,
  ) {
    return _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var name = reference.elementName.ifEqualThen('new', '');
      var element = ConstructorElementImpl(name, -1);
      element.typeName = _reader.readOptionalStringReference();
      element.name2 = _reader.readStringReference();
      var linkedData = ConstructorElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      element.setLinkedData(reference, linkedData);
      ConstructorElementFlags.read(_reader, element);
      element.parameters = _readParameters();
      return element;
    });
  }

  DirectiveUriImpl _readDirectiveUri({
    required CompilationUnitElementImpl containerUnit,
  }) {
    DirectiveUriWithRelativeUriStringImpl readWithRelativeUriString() {
      var relativeUriString = _reader.readStringReference();
      return DirectiveUriWithRelativeUriStringImpl(
        relativeUriString: relativeUriString,
      );
    }

    DirectiveUriWithRelativeUriImpl readWithRelativeUri() {
      var parent = readWithRelativeUriString();
      var relativeUri = uriCache.parse(_reader.readStringReference());
      return DirectiveUriWithRelativeUriImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: relativeUri,
      );
    }

    DirectiveUriWithSourceImpl readWithSource() {
      var parent = readWithRelativeUri();

      var analysisContext = _elementFactory.analysisContext;
      var sourceFactory = analysisContext.sourceFactory;

      var sourceUriStr = _reader.readStringReference();
      var sourceUri = uriCache.parse(sourceUriStr);
      var source = sourceFactory.forUri2(sourceUri);

      // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49431
      var fixedSource = source ?? sourceFactory.forUri('dart:math')!;

      return DirectiveUriWithSourceImpl(
        relativeUriString: parent.relativeUriString,
        relativeUri: parent.relativeUri,
        source: fixedSource,
      );
    }

    var kindIndex = _reader.readByte();
    var kind = DirectiveUriKind.values[kindIndex];
    switch (kind) {
      case DirectiveUriKind.withLibrary:
        var parent = readWithSource();
        return DirectiveUriWithLibraryImpl.read(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          source: parent.source,
        );
      case DirectiveUriKind.withUnit:
        var parent = readWithSource();
        var unitElement = _readUnitElement(
          containerUnit: containerUnit,
          unitSource: parent.source,
        );
        return DirectiveUriWithUnitImpl(
          relativeUriString: parent.relativeUriString,
          relativeUri: parent.relativeUri,
          unit: unitElement,
        );
      case DirectiveUriKind.withSource:
        return readWithSource();
      case DirectiveUriKind.withRelativeUri:
        return readWithRelativeUri();
      case DirectiveUriKind.withRelativeUriString:
        return readWithRelativeUriString();
      case DirectiveUriKind.withNothing:
        return DirectiveUriImpl();
    }
  }

  EnumElementImpl _readEnumElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();
    var name = fragmentName ?? '';

    var fragment = EnumElementImpl(name, -1);
    fragment.name2 = fragmentName;

    if (reference2.element2 case EnumElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = EnumElementImpl2(reference2, fragment);
      _libraryElement.enums.add(element);
    }

    var linkedData = EnumElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    EnumElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElementImpl>[];

    _readFields(unitElement, fragment, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, fragment, reference, accessors, fields, '@field');
    fragment.fields = fields.toFixedList();
    fragment.accessors = accessors.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readEnums(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.enums = _reader.readTypedList(() {
      return _readEnumElement(unitElement, unitReference);
    });
  }

  ExportedReference _readExportedReference() {
    var kind = _reader.readByte();
    if (kind == 0) {
      var index = _reader.readUInt30();
      var reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceDeclared(
        reference: reference,
      );
    } else if (kind == 1) {
      var index = _reader.readUInt30();
      var reference = _referenceReader.referenceOfIndex(index);
      return ExportedReferenceExported(
        reference: reference,
        locations: _reader.readTypedList(_readExportLocation),
      );
    } else {
      throw StateError('kind: $kind');
    }
  }

  LibraryExportElementImpl _readExportElement({
    required CompilationUnitElementImpl containerUnit,
  }) {
    return LibraryExportElementImpl(
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      exportKeywordOffset: -1,
      uri: _readDirectiveUri(
        containerUnit: containerUnit,
      ),
    );
  }

  ExportLocation _readExportLocation() {
    return ExportLocation(
      fragmentIndex: _reader.readUInt30(),
      exportIndex: _reader.readUInt30(),
    );
  }

  ExtensionElementImpl _readExtensionElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();
    var name = fragmentName;

    var fragment = ExtensionElementImpl(name, -1);
    fragment.name2 = fragmentName;

    if (reference2.element2 case ExtensionElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ExtensionElementImpl2(reference2, fragment);
      _libraryElement.extensions.add(element);
    }

    fragment.setLinkedData(
      reference,
      ExtensionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    ExtensionElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var accessors = <PropertyAccessorElementImpl>[];
    var fields = <FieldElementImpl>[];
    _readPropertyAccessors(
        unitElement, fragment, reference, accessors, fields, '@field');
    _readFields(unitElement, fragment, reference, accessors, fields);
    fragment.accessors = accessors;
    fragment.fields = fields;

    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readExtensions(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.extensions = _reader.readTypedList(() {
      return _readExtensionElement(unitElement, unitReference);
    });
  }

  ExtensionTypeElementImpl _readExtensionTypeElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();
    var name = fragmentName ?? '';

    var fragment = ExtensionTypeElementImpl(name, -1);
    fragment.name2 = fragmentName;

    if (reference2.element2 case ExtensionTypeElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = ExtensionTypeElementImpl2(reference2, fragment);
      _libraryElement.extensionTypes.add(element);
    }

    fragment.setLinkedData(
      reference,
      ExtensionTypeElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    ExtensionTypeElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldElementImpl>[];
    var accessors = <PropertyAccessorElementImpl>[];
    _readFields(unitElement, fragment, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, fragment, reference, accessors, fields, '@field');
    fragment.fields = fields;
    fragment.accessors = accessors;

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);

    return fragment;
  }

  void _readExtensionTypes(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.extensionTypes = _reader.readTypedList(() {
      return _readExtensionTypeElement(unitElement, unitReference);
    });
  }

  FeatureSet _readFeatureSet() {
    var featureSetEncoded = _reader.readUint8List();
    return ExperimentStatus.fromStorage(featureSetEncoded);
  }

  FieldElementImpl _readFieldElement(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var getterReference = _readOptionalReference();
    var setterReference = _readOptionalReference();
    var fragmentName = _readFragmentName();

    // TODO(scheglov): we do this only because FieldElement2 uses this name.
    var name = _reader.readStringReference();
    var isConstElement = _reader.readBool();

    FieldElementImpl element;
    if (isConstElement) {
      element = ConstFieldElementImpl(name, -1);
    } else {
      element = FieldElementImpl(name, -1);
    }
    element.name2 = fragmentName;

    var linkedData = FieldElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    element.setLinkedData(reference, linkedData);

    FieldElementFlags.read(_reader, element);
    element.typeInferenceError = _readTopLevelInferenceError();

    if (!element.isAugmentation) {
      if (getterReference != null) {
        var getter = element.createImplicitGetter(getterReference);
        getter.hasEnclosingTypeParameterReference =
            element.hasEnclosingTypeParameterReference;
      }
      if (element.hasSetter && setterReference != null) {
        var setter = element.createImplicitSetter(setterReference);
        setter.hasEnclosingTypeParameterReference =
            element.hasEnclosingTypeParameterReference;
      }
    }

    return element;
  }

  void _readFields(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
    List<PropertyAccessorElementImpl> accessors,
    List<FieldElementImpl> variables,
  ) {
    var createdElements = <FieldElementImpl>[];
    var variableElementCount = _reader.readUInt30();
    for (var i = 0; i < variableElementCount; i++) {
      var variable =
          _readFieldElement(unitElement, classElement, classReference);
      createdElements.add(variable);
      variables.add(variable);

      var getter = variable.getter;
      if (getter is GetterFragmentImpl) {
        accessors.add(getter);
      }

      var setter = variable.setter;
      if (setter is SetterFragmentImpl) {
        accessors.add(setter);
      }
    }
  }

  String? _readFragmentName() {
    return _reader.readOptionalStringReference();
  }

  void _readFunctions(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.functions = _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var reference2 = _readReference();
      var fragmentName = _readFragmentName();
      var name = reference.elementName;

      var fragment = TopLevelFunctionFragmentImpl(name, -1);
      fragment.name2 = fragmentName;

      if (reference2.element2 case TopLevelFunctionElementImpl element?) {
        fragment.element = element;
      } else {
        var element = TopLevelFunctionElementImpl(reference2, fragment);
        _libraryElement.topLevelFunctions.add(element);
      }

      var linkedData = FunctionElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      fragment.setLinkedData(reference, linkedData);

      FunctionElementFlags.read(_reader, fragment);
      fragment.typeParameters = _readTypeParameters();
      fragment.parameters = _readParameters();

      return fragment;
    });
  }

  LibraryImportElementImpl _readImportElement({
    required CompilationUnitElementImpl containerUnit,
  }) {
    var element = LibraryImportElementImpl(
      combinators: _reader.readTypedList(_readNamespaceCombinator),
      importKeywordOffset: -1,
      prefix: _readImportElementPrefix(
        containerUnit: containerUnit,
      ),
      prefix2: _readLibraryImportPrefixFragment(
        libraryFragment: containerUnit,
      ),
      uri: _readDirectiveUri(
        containerUnit: containerUnit,
      ),
    );
    LibraryImportElementFlags.read(_reader, element);
    return element;
  }

  ImportElementPrefixImpl? _readImportElementPrefix({
    required CompilationUnitElementImpl containerUnit,
  }) {
    PrefixElementImpl buildElement(String name, Reference reference) {
      // TODO(scheglov): Make reference required.
      var existing = reference.element;
      if (existing is PrefixElementImpl) {
        return existing;
      } else {
        var result = PrefixElementImpl(name, -1, reference: reference);
        result.enclosingElement3 = containerUnit;
        return result;
      }
    }

    var kindIndex = _reader.readByte();
    var kind = ImportElementPrefixKind.values[kindIndex];
    switch (kind) {
      case ImportElementPrefixKind.isDeferred:
        var name = _reader.readStringReference();
        var reference = _readReference();
        return DeferredImportElementPrefixImpl(
          element: buildElement(name, reference),
        );
      case ImportElementPrefixKind.isNotDeferred:
        var name = _reader.readStringReference();
        var reference = _readReference();
        return ImportElementPrefixImpl(
          element: buildElement(name, reference),
        );
      case ImportElementPrefixKind.isNull:
        return null;
    }
  }

  LibraryLanguageVersion _readLanguageVersion() {
    var packageMajor = _reader.readUInt30();
    var packageMinor = _reader.readUInt30();
    var package = Version(packageMajor, packageMinor, 0);

    Version? override;
    if (_reader.readBool()) {
      var overrideMajor = _reader.readUInt30();
      var overrideMinor = _reader.readUInt30();
      override = Version(overrideMajor, overrideMinor, 0);
    }

    return LibraryLanguageVersion(package: package, override: override);
  }

  PrefixFragmentImpl? _readLibraryImportPrefixFragment({
    required CompilationUnitElementImpl libraryFragment,
  }) {
    return _reader.readOptionalObject(() {
      var fragmentName = _readFragmentName();
      var reference = _readReference();
      var isDeferred = _reader.readBool();
      var fragment = PrefixFragmentImpl(
        enclosingFragment: libraryFragment,
        name2: fragmentName,
        nameOffset2: null,
        isDeferred: isDeferred,
      );

      var element = reference.element2 as PrefixElementImpl2?;
      if (element == null) {
        element = PrefixElementImpl2(
          reference: reference,
          firstFragment: fragment,
        );
      } else {
        element.addFragment(fragment);
      }

      fragment.element = element;
      return fragment;
    });
  }

  List<MethodElementImpl> _readMethods(
    CompilationUnitElementImpl unitElement,
    ElementImpl enclosingElement,
    Reference enclosingReference,
  ) {
    return _reader.readTypedList(() {
      var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
      var reference = _readReference();
      var fragmentName = _readFragmentName();
      // TODO(scheglov): we do this only because MethodElement2 uses this name.
      var name = _reader.readStringReference();
      var fragment = MethodElementImpl(name, -1);
      fragment.name2 = fragmentName;

      var linkedData = MethodElementLinkedData(
        reference: reference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      );
      fragment.setLinkedData(reference, linkedData);
      MethodElementFlags.read(_reader, fragment);
      fragment.typeParameters = _readTypeParameters();
      fragment.parameters = _readParameters();
      fragment.typeInferenceError = _readTopLevelInferenceError();
      return fragment;
    });
  }

  MixinElementImpl _readMixinElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();

    var reference2 = _readReference();

    var fragmentName = _readFragmentName();
    var name = fragmentName ?? '';

    var fragment = MixinElementImpl(name, -1);
    fragment.name2 = fragmentName;

    if (reference2.element2 case MixinElementImpl2 element?) {
      fragment.augmentedInternal = element;
    } else {
      var element = MixinElementImpl2(reference2, fragment);
      _libraryElement.mixins.add(element);
    }

    var linkedData = MixinElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    MixinElementFlags.read(_reader, fragment);
    fragment.typeParameters = _readTypeParameters();

    var fields = <FieldElementImpl>[];
    var accessors = <PropertyAccessorElementImpl>[];
    _readFields(unitElement, fragment, reference, accessors, fields);
    _readPropertyAccessors(
        unitElement, fragment, reference, accessors, fields, '@field');
    fragment.fields = fields.toFixedList();
    fragment.accessors = accessors.toFixedList();

    fragment.constructors = _readConstructors(unitElement, fragment, reference);
    fragment.methods = _readMethods(unitElement, fragment, reference);
    fragment.superInvokedNames = _reader.readStringReferenceList();

    return fragment;
  }

  void _readMixins(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.mixins = _reader.readTypedList(() {
      return _readMixinElement(unitElement, unitReference);
    });
  }

  NamespaceCombinator _readNamespaceCombinator() {
    var tag = _reader.readByte();
    if (tag == Tag.HideCombinator) {
      var combinator = HideElementCombinatorImpl();
      combinator.hiddenNames = _reader.readStringReferenceList();
      return combinator;
    } else if (tag == Tag.ShowCombinator) {
      var combinator = ShowElementCombinatorImpl();
      combinator.shownNames = _reader.readStringReferenceList();
      return combinator;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  /// Read the reference of a non-local element.
  Reference? _readOptionalReference() {
    return _reader.readOptionalObject(() => _readReference());
  }

  // TODO(scheglov): Deduplicate parameter reading implementation.
  List<ParameterElementImpl> _readParameters() {
    return _reader.readTypedList(() {
      var fragmentName = _readFragmentName();
      var name = _reader.readStringReference();
      var isDefault = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var isSuperFormal = _reader.readBool();
      var reference = _readOptionalReference();

      var kindIndex = _reader.readByte();
      var kind = ResolutionReader._formalParameterKind(kindIndex);

      ParameterElementImpl element;
      if (!isDefault) {
        if (isInitializingFormal) {
          element = FieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else if (isSuperFormal) {
          element = SuperFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else {
          element = ParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        }
      } else {
        if (isInitializingFormal) {
          element = DefaultFieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else if (isSuperFormal) {
          element = DefaultSuperFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        } else {
          element = DefaultParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          );
        }
        if (reference != null) {
          element.reference = reference;
          reference.element = element;
        }
      }
      element.name2 = fragmentName;
      ParameterElementFlags.read(_reader, element);
      element.typeParameters = _readTypeParameters();
      element.parameters = _readParameters();
      return element;
    });
  }

  PartElementImpl _readPartElement({
    required CompilationUnitElementImpl containerUnit,
  }) {
    var uri = _readDirectiveUri(
      containerUnit: containerUnit,
    );

    return PartElementImpl(
      uri: uri,
    );
  }

  PropertyAccessorElementImpl _readPropertyAccessorElement(
    CompilationUnitElementImpl unitElement,
    ElementImpl classElement,
    Reference classReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var fragmentName = _readFragmentName();
    var name = reference.elementName;
    var flags = _reader.readUInt30();

    var fragment = PropertyAccessorElementFlags.isGetter(flags)
        ? GetterFragmentImpl(name, -1)
        : SetterFragmentImpl(name, -1);
    fragment.name2 = fragmentName;

    var linkedData = PropertyAccessorElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    PropertyAccessorElementFlags.setFlagsBasedOnFlagByte(fragment, flags);
    fragment.parameters = _readParameters();
    return fragment;
  }

  void _readPropertyAccessors(
    CompilationUnitElementImpl unitElement,
    ElementImpl enclosingElement,
    Reference enclosingReference,
    List<PropertyAccessorElementImpl> accessorFragments,
    List<PropertyInducingElementImpl> propertyFragments,
    String containerRefName, {
    List<TopLevelVariableElementImpl2>? variables2,
  }) {
    var accessorCount = _reader.readUInt30();
    for (var i = 0; i < accessorCount; i++) {
      var accessor = _readPropertyAccessorElement(
        unitElement,
        enclosingElement,
        enclosingReference,
      );
      accessorFragments.add(accessor);

      if (accessor.isAugmentation) {
        continue;
      }

      // Read the property references.
      var propertyFragmentReference = _readReference();
      // TODO(scheglov): should be required?
      var propertyElementReference = _readOptionalReference();

      var name = accessor.displayName;

      bool canUseExisting(PropertyInducingElementImpl property) {
        return property.isSynthetic ||
            accessor.isSetter && property.setter == null;
      }

      PropertyInducingElementImpl propertyFragment;
      var existing = propertyFragmentReference.element;
      if (enclosingElement is CompilationUnitElementImpl) {
        if (existing is TopLevelVariableElementImpl &&
            canUseExisting(existing)) {
          propertyFragment = existing;
        } else {
          var variableFragment = TopLevelVariableElementImpl(name, -1)
            ..enclosingElement3 = enclosingElement
            ..reference = propertyFragmentReference
            ..isSynthetic = true
            ..name2 = accessor.name2;
          propertyFragment = variableFragment;
          propertyFragmentReference.element ??= propertyFragment;
          propertyFragments.add(variableFragment);

          // TODO(scheglov): should be required?
          propertyElementReference!;
          var variableElement = TopLevelVariableElementImpl2(
            propertyElementReference,
            variableFragment,
          );
          variables2!.add(variableElement);
        }
      } else {
        var isPromotable = _reader.readBool();
        if (existing is FieldElementImpl && canUseExisting(existing)) {
          propertyFragment = existing;
        } else {
          propertyFragment = FieldElementImpl(name, -1)
            ..enclosingElement3 = enclosingElement
            ..reference = propertyFragmentReference
            ..name2 = accessor.name2
            ..isStatic = accessor.isStatic
            ..isSynthetic = true
            ..isPromotable = isPromotable
            ..hasEnclosingTypeParameterReference =
                accessor.hasEnclosingTypeParameterReference;
          propertyFragmentReference.element ??= propertyFragment;
          propertyFragments.add(propertyFragment);
        }
      }

      accessor.variable2 = propertyFragment;
      switch (accessor) {
        case GetterFragmentImpl():
          propertyFragment.getter = accessor;
        case SetterFragmentImpl():
          propertyFragment.setter = accessor;
          if (propertyFragment.isSynthetic) {
            propertyFragment.isFinal = false;
          }
      }
    }
  }

  /// Read the reference of a non-local element.
  Reference _readReference() {
    var referenceIndex = _reader.readUInt30();
    return _referenceReader.referenceOfIndex(referenceIndex);
  }

  TopLevelInferenceError? _readTopLevelInferenceError() {
    var kindIndex = _reader.readByte();
    var kind = TopLevelInferenceErrorKind.values[kindIndex];
    if (kind == TopLevelInferenceErrorKind.none) {
      return null;
    }
    return TopLevelInferenceError(
      kind: kind,
      arguments: _reader.readStringReferenceList(),
    );
  }

  TopLevelVariableElementImpl _readTopLevelVariableElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var reference = _readReference();
    var reference2 = _readReference();
    var getterReference = _readOptionalReference();
    var setterReference = _readOptionalReference();
    var fragmentName = _readFragmentName();

    // TODO(scheglov): we do this only because FieldElement2 uses this name.
    var name = _reader.readStringReference();
    var isConst = _reader.readBool();

    TopLevelVariableElementImpl fragment;
    if (isConst) {
      fragment = ConstTopLevelVariableElementImpl(name, -1);
    } else {
      fragment = TopLevelVariableElementImpl(name, -1);
    }
    fragment.name2 = fragmentName;

    if (reference2.element2 case TopLevelVariableElementImpl2 element) {
      fragment.element = element;
    } else {
      var element = TopLevelVariableElementImpl2(reference2, fragment);
      _libraryElement.topLevelVariables.add(element);
    }

    var linkedData = TopLevelVariableElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    fragment.isConst = isConst;
    TopLevelVariableElementFlags.read(_reader, fragment);
    fragment.typeInferenceError = _readTopLevelInferenceError();

    if (getterReference != null) {
      var getter = fragment.createImplicitGetter(getterReference);
      getter.hasEnclosingTypeParameterReference = false;
    }
    if (fragment.hasSetter && setterReference != null) {
      var getter = fragment.createImplicitSetter(setterReference);
      getter.hasEnclosingTypeParameterReference = false;
    }

    return fragment;
  }

  void _readTopLevelVariables(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
    List<PropertyAccessorElementImpl> accessors,
    List<TopLevelVariableElementImpl> variables,
  ) {
    var variableElementCount = _reader.readUInt30();
    for (var i = 0; i < variableElementCount; i++) {
      var variable = _readTopLevelVariableElement(unitElement, unitReference);
      variables.add(variable);

      var getter = variable.getter;
      if (getter is GetterFragmentImpl) {
        accessors.add(getter);
      }

      var setter = variable.setter;
      if (setter is SetterFragmentImpl) {
        accessors.add(setter);
      }
    }
  }

  TypeAliasElementImpl _readTypeAliasElement(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();
    var reference = _readReference();
    var reference2 = _readReference();
    var fragmentName = _readFragmentName();
    var name = _reader.readStringReference();

    var isFunctionTypeAliasBased = _reader.readBool();

    TypeAliasElementImpl fragment;
    if (isFunctionTypeAliasBased) {
      fragment = TypeAliasElementImpl(name, -1);
      fragment.isFunctionTypeAliasBased = true;
    } else {
      fragment = TypeAliasElementImpl(name, -1);
    }
    fragment.name2 = fragmentName;

    if (reference2.element2 case TypeAliasElementImpl2 element) {
      fragment.element = element;
    } else {
      var element = TypeAliasElementImpl2(reference2, fragment);
      _libraryElement.typeAliases.add(element);
    }

    var linkedData = TypeAliasElementLinkedData(
      reference: reference,
      libraryReader: this,
      unitElement: unitElement,
      offset: resolutionOffset,
    );
    fragment.setLinkedData(reference, linkedData);

    fragment.isFunctionTypeAliasBased = isFunctionTypeAliasBased;
    TypeAliasElementFlags.read(_reader, fragment);

    fragment.typeParameters = _readTypeParameters();

    return fragment;
  }

  void _readTypeAliases(
    CompilationUnitElementImpl unitElement,
    Reference unitReference,
  ) {
    unitElement.typeAliases = _reader.readTypedList(() {
      return _readTypeAliasElement(unitElement, unitReference);
    });
  }

  List<TypeParameterElementImpl> _readTypeParameters() {
    return _reader.readTypedList(() {
      var name = _reader.readStringReference();
      var fragmentName = _readFragmentName();
      var varianceEncoding = _reader.readByte();
      var variance = _decodeVariance(varianceEncoding);
      var element = TypeParameterElementImpl(name, -1);
      element.name2 = fragmentName;
      element.variance = variance;
      return element;
    });
  }

  CompilationUnitElementImpl _readUnitElement({
    required CompilationUnitElementImpl? containerUnit,
    required Source unitSource,
  }) {
    var resolutionOffset = _baseResolutionOffset + _reader.readUInt30();

    var unitElement = CompilationUnitElementImpl(
      library: _libraryElement,
      source: unitSource,
      lineInfo: LineInfo([0]),
    );

    var unitReference =
        _reference.getChild('@fragment').getChild('${unitSource.uri}');
    unitElement.setLinkedData(
      unitReference,
      CompilationUnitElementLinkedData(
        reference: unitReference,
        libraryReader: this,
        unitElement: unitElement,
        offset: resolutionOffset,
      ),
    );

    unitElement.uri = _reader.readOptionalStringReference();
    unitElement.isSynthetic = _reader.readBool();

    unitElement.libraryImports = _reader.readTypedList(() {
      return _readImportElement(
        containerUnit: unitElement,
      );
    });

    unitElement.libraryExports = _reader.readTypedList(() {
      return _readExportElement(
        containerUnit: unitElement,
      );
    });

    _readClasses(unitElement, unitReference);
    _readEnums(unitElement, unitReference);
    _readExtensions(unitElement, unitReference);
    _readExtensionTypes(unitElement, unitReference);
    _readFunctions(unitElement, unitReference);
    _readMixins(unitElement, unitReference);
    _readTypeAliases(unitElement, unitReference);

    var accessorFragments = <PropertyAccessorElementImpl>[];
    var variableFragments = <TopLevelVariableElementImpl>[];
    _readTopLevelVariables(
        unitElement, unitReference, accessorFragments, variableFragments);
    _readPropertyAccessors(
      unitElement,
      unitElement,
      unitReference,
      accessorFragments,
      variableFragments,
      '@topLevelVariable',
      variables2: _libraryElement.topLevelVariables,
    );
    unitElement.accessors = accessorFragments.toFixedList();
    unitElement.topLevelVariables = variableFragments.toFixedList();

    unitElement.parts = _reader.readTypedList(() {
      return _readPartElement(
        containerUnit: unitElement,
      );
    });

    return unitElement;
  }

  static Variance? _decodeVariance(int index) {
    var tag = TypeParameterVarianceTag.values[index];
    switch (tag) {
      case TypeParameterVarianceTag.legacy:
        return null;
      case TypeParameterVarianceTag.unrelated:
        return Variance.unrelated;
      case TypeParameterVarianceTag.covariant:
        return Variance.covariant;
      case TypeParameterVarianceTag.contravariant:
        return Variance.contravariant;
      case TypeParameterVarianceTag.invariant:
        return Variance.invariant;
    }
  }
}

class MethodElementLinkedData extends ElementLinkedData<MethodElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MethodElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(MethodElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    _readFormalParameters(reader, element.parameters);
    element.returnType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

class MixinElementLinkedData extends ElementLinkedData<MixinElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  MixinElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(MixinElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: element.enclosingElement3,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.superclassConstraints = reader._readInterfaceTypeList();
    element.interfaces = reader._readInterfaceTypeList();

    var augmented = element.augmentedInternal;
    augmented.superclassConstraints = reader._readInterfaceTypeList();

    applyConstantOffsets?.perform();
  }
}

class PropertyAccessorElementLinkedData
    extends ElementLinkedData<PropertyAccessorElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  PropertyAccessorElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(PropertyAccessorElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    _addEnclosingElementTypeParameters(reader, element);

    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );

    element.returnType = reader.readRequiredType();
    _readFormalParameters(reader, element.parameters);

    applyConstantOffsets?.perform();
  }
}

/// Helper for reading elements and types from their binary encoding.
class ResolutionReader {
  final LinkedElementFactory _elementFactory;
  final _ReferenceReader _referenceReader;
  final SummaryDataReader _reader;

  /// The stack of [TypeParameterElementImpl]s and [ParameterElementImpl] that are
  /// available in the scope of [readElement] and [readType].
  ///
  /// This stack is shared with the client of the reader, and update mostly
  /// by the client. However it is also updated during [_readFunctionType].
  final List<ElementImpl> _localElements = [];

  ResolutionReader(
    this._elementFactory,
    this._referenceReader,
    this._reader,
  );

  LibraryElementImpl libraryOfUri(Uri uri) {
    return _elementFactory.libraryOfUri2(uri);
  }

  bool readBool() {
    return _reader.readBool();
  }

  int readByte() {
    return _reader.readByte();
  }

  double readDouble() {
    return _reader.readDouble();
  }

  ElementOrMember? readElement() {
    var memberFlags = _reader.readByte();
    var element = _readRawElement();

    if (element == null) {
      return null;
    }

    if (memberFlags == Tag.RawElement) {
      return element;
    }

    if (memberFlags == Tag.MemberWithTypeArguments) {
      var enclosing = element.enclosingElement3 as InstanceElementImpl;

      var firstFragment = enclosing.element.firstFragment;
      var declarationTypeParameters =
          firstFragment.typeParameters.map((tp) => tp.asElement2).toList();

      var substitution = Substitution.empty;
      var typeArguments = _readTypeList();
      if (typeArguments.isNotEmpty) {
        substitution = Substitution.fromPairs2(
          declarationTypeParameters,
          typeArguments,
        );
      }

      if (element is ExecutableElementImpl) {
        return ExecutableMember.from2(element, substitution);
      } else {
        element as FieldElementImpl;
        return FieldMember.from2(element, substitution);
      }
    }

    throw UnimplementedError('memberFlags: $memberFlags');
  }

  Element2? readElement2() {
    var element = readElement();
    switch (element) {
      case null:
        return null;
      case ElementImpl():
        return element.asElement2;
      case ExecutableMember():
        return element;
      default:
        throw UnimplementedError('${element.runtimeType}');
    }
  }

  List<T> readElementList2<T extends Element2>() {
    return _reader.readTypedListCast<T>(readElement2);
  }

  T readEnum<T extends Enum>(List<T> values) {
    return _reader.readEnum(values);
  }

  Map<K, V> readMap<K, V>({
    required K Function() readKey,
    required V Function() readValue,
  }) {
    return _reader.readMap(
      readKey: readKey,
      readValue: readValue,
    );
  }

  FunctionTypeImpl? readOptionalFunctionType() {
    var type = readType();
    return type is FunctionTypeImpl ? type : null;
  }

  T? readOptionalObject<T>(T Function() read) {
    return _reader.readOptionalObject(read);
  }

  List<TypeImpl>? readOptionalTypeList() {
    if (_reader.readBool()) {
      return _readTypeList();
    } else {
      return null;
    }
  }

  TypeImpl readRequiredType() {
    return readType()!;
  }

  SourceRange readSourceRange() {
    var offset = readUInt30();
    var length = readUInt30();
    return SourceRange(offset, length);
  }

  String readStringReference() {
    return _reader.readStringReference();
  }

  List<String> readStringReferenceList() {
    return _reader.readStringReferenceList();
  }

  TypeImpl? readType() {
    var tag = _reader.readByte();
    if (tag == Tag.NullType) {
      return null;
    } else if (tag == Tag.DynamicType) {
      var type = DynamicTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else if (tag == Tag.FunctionType) {
      var type = _readFunctionType();
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType) {
      var element = readElement() as InterfaceElementImpl;
      var typeArguments = _readTypeList();
      var nullability = _readNullability();
      var type = InterfaceTypeImpl(
        element: element.asElement2,
        typeArguments: typeArguments,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_none) {
      var element = readElement() as InterfaceElementImpl;
      var type = element.instantiateImpl(
          typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none);
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InterfaceType_noTypeArguments_question) {
      var element = readElement() as InterfaceElementImpl;
      var type = element.instantiateImpl(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.question,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.InvalidType) {
      var type = InvalidTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else if (tag == Tag.NeverType) {
      var nullability = _readNullability();
      var type = NeverTypeImpl.instance.withNullability(nullability);
      return _readAliasElementArguments(type);
    } else if (tag == Tag.RecordType) {
      var type = _readRecordType();
      return _readAliasElementArguments(type);
    } else if (tag == Tag.TypeParameterType) {
      var element = readElement() as TypeParameterElementImpl;
      var nullability = _readNullability();
      var type = TypeParameterTypeImpl(
        element3: element.asElement2,
        nullabilitySuffix: nullability,
      );
      return _readAliasElementArguments(type);
    } else if (tag == Tag.VoidType) {
      var type = VoidTypeImpl.instance;
      return _readAliasElementArguments(type);
    } else {
      throw UnimplementedError('$tag');
    }
  }

  List<T> readTypedList<T>(T Function() read) {
    return _reader.readTypedList(read);
  }

  int readUInt30() {
    return _reader.readUInt30();
  }

  int readUInt32() {
    return _reader.readUInt32();
  }

  void setOffset(int offset) {
    _reader.offset = offset;
  }

  void _addFormalParameters(List<ParameterElementImpl> parameters) {
    for (var parameter in parameters) {
      _localElements.add(parameter);
    }
  }

  void _addTypeParameters(List<TypeParameterElementImpl> typeParameters) {
    for (var typeParameter in typeParameters) {
      _localElements.add(typeParameter);
    }
  }

  ElementImpl? _readAliasedElement(CompilationUnitElementImpl unitElement) {
    var tag = _reader.readByte();
    if (tag == AliasedElementTag.nothing) {
      return null;
    } else if (tag == AliasedElementTag.genericFunctionElement) {
      var typeParameters = _readTypeParameters(unitElement);
      var formalParameters = _readFormalParameters(unitElement);
      var returnType = readRequiredType();

      _localElements.length -= typeParameters.length;

      return GenericFunctionTypeElementImpl.forOffset(-1)
        ..typeParameters = typeParameters
        ..parameters = formalParameters
        ..returnType = returnType;
    } else {
      throw UnimplementedError('tag: $tag');
    }
  }

  TypeImpl _readAliasElementArguments(TypeImpl type) {
    var aliasElement = _readRawElement();
    if (aliasElement is TypeAliasElementImpl) {
      var aliasArguments = _readTypeList();
      if (type is DynamicTypeImpl) {
        // TODO(scheglov): add support for `dynamic` aliasing
        return type;
      } else if (type is FunctionTypeImpl) {
        return FunctionTypeImpl(
          typeFormals: type.typeFormals,
          parameters: type.parameters,
          returnType: type.returnType,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasElement.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is InterfaceTypeImpl) {
        return InterfaceTypeImpl(
          element: type.element3,
          typeArguments: type.typeArguments,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasElement.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is RecordTypeImpl) {
        return RecordTypeImpl(
          positionalFields: type.positionalFields,
          namedFields: type.namedFields,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasElement.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is TypeParameterTypeImpl) {
        return TypeParameterTypeImpl(
          element3: type.element3,
          nullabilitySuffix: type.nullabilitySuffix,
          alias: InstantiatedTypeAliasElementImpl(
            element2: aliasElement.asElement2,
            typeArguments: aliasArguments,
          ),
        );
      } else if (type is VoidTypeImpl) {
        // TODO(scheglov): add support for `void` aliasing
        return type;
      } else {
        throw UnimplementedError('${type.runtimeType}');
      }
    }
    return type;
  }

  List<ElementAnnotationImpl> _readAnnotationList({
    required CompilationUnitElementImpl unitElement,
  }) {
    return readTypedList(() {
      var ast = _readRequiredNode() as AnnotationImpl;
      return ElementAnnotationImpl(unitElement)
        ..annotationAst = ast
        ..element2 = ast.element2;
    });
  }

  List<ParameterElementImpl> _readFormalParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    return readTypedList(() {
      var kindIndex = _reader.readByte();
      var kind = _formalParameterKind(kindIndex);
      var isDefault = _reader.readBool();
      var hasImplicitType = _reader.readBool();
      var isInitializingFormal = _reader.readBool();
      var typeParameters = _readTypeParameters(unitElement);
      var type = readRequiredType();
      var name = readStringReference();
      if (!isDefault) {
        ParameterElementImpl element;
        if (isInitializingFormal) {
          element = FieldFormalParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          )..type = type;
        } else {
          element = ParameterElementImpl(
            name: name,
            nameOffset: -1,
            name2: name.nullIfEmpty,
            nameOffset2: null,
            parameterKind: kind,
          )..type = type;
        }
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov): reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readAnnotationList(unitElement: unitElement);
        }
        return element;
      } else {
        var element = DefaultParameterElementImpl(
          name: name,
          nameOffset: -1,
          name2: name.nullIfEmpty,
          nameOffset2: null,
          parameterKind: kind,
        )..type = type;
        element.hasImplicitType = hasImplicitType;
        element.typeParameters = typeParameters;
        element.parameters = _readFormalParameters(unitElement);
        // TODO(scheglov): reuse for formal parameters
        _localElements.length -= typeParameters.length;
        if (unitElement != null) {
          element.metadata = _readAnnotationList(unitElement: unitElement);
        }
        return element;
      }
    });
  }

  // TODO(scheglov): Optimize for write/read of types without type parameters.
  FunctionTypeImpl _readFunctionType() {
    // TODO(scheglov): reuse for formal parameters
    var typeParameters = _readTypeParameters(null);
    var returnType = readRequiredType();
    var formalParameters = _readFormalParameters(null);

    var nullability = _readNullability();

    _localElements.length -= typeParameters.length;

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullability,
    );
  }

  InterfaceTypeImpl _readInterfaceType() {
    return readType() as InterfaceTypeImpl;
  }

  List<InterfaceTypeImpl> _readInterfaceTypeList() {
    return readTypedList(_readInterfaceType);
  }

  List<T> _readNodeList<T>() {
    return readTypedList(() {
      return _readRequiredNode() as T;
    });
  }

  NullabilitySuffix _readNullability() {
    var index = _reader.readByte();
    return NullabilitySuffix.values[index];
  }

  ExpressionImpl? _readOptionalExpression() {
    if (_reader.readBool()) {
      return _readRequiredNode() as ExpressionImpl;
    } else {
      return null;
    }
  }

  InterfaceType? _readOptionalInterfaceType() {
    return readType() as InterfaceType?;
  }

  ElementImpl? _readRawElement() {
    var index = _reader.readUInt30();

    if ((index & 0x1) == 0x1) {
      return _localElements[index >> 1];
    }

    var referenceIndex = index >> 1;
    var reference = _referenceReader.referenceOfIndex(referenceIndex);

    return _elementFactory.elementOfReference(reference);
  }

  RecordTypeImpl _readRecordType() {
    var positionalFields = readTypedList(() {
      return RecordTypePositionalFieldImpl(
        type: readRequiredType(),
      );
    });

    var namedFields = readTypedList(() {
      return RecordTypeNamedFieldImpl(
        name: _reader.readStringReference(),
        type: readRequiredType(),
      );
    });

    var nullabilitySuffix = _readNullability();

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  AstNode _readRequiredNode() {
    var astReader = AstBinaryReader(reader: this);
    return astReader.readNode();
  }

  List<TypeImpl> _readTypeList() {
    return readTypedList(() {
      return readRequiredType();
    });
  }

  List<TypeParameterElementImpl> _readTypeParameters(
    CompilationUnitElementImpl? unitElement,
  ) {
    var typeParameters = readTypedList(() {
      var name = readStringReference();
      var typeParameter = TypeParameterElementImpl(name, -1);
      _localElements.add(typeParameter);
      return typeParameter;
    });

    for (var typeParameter in typeParameters) {
      typeParameter.bound = readType();
      if (unitElement != null) {
        typeParameter.metadata = _readAnnotationList(unitElement: unitElement);
      }
    }
    return typeParameters;
  }

  static ParameterKind _formalParameterKind(int encoding) {
    if (encoding == Tag.ParameterKindRequiredPositional) {
      return ParameterKind.REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (encoding == Tag.ParameterKindRequiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    } else if (encoding == Tag.ParameterKindOptionalNamed) {
      return ParameterKind.NAMED;
    } else {
      throw StateError('Unexpected parameter kind encoding: $encoding');
    }
  }
}

class TopLevelVariableElementLinkedData
    extends ElementLinkedData<TopLevelVariableElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TopLevelVariableElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(TopLevelVariableElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    element.type = reader.readRequiredType();

    if (element is ConstTopLevelVariableElementImpl) {
      var initializer = reader._readOptionalExpression();
      if (initializer != null) {
        element.constantInitializer = initializer;
        ConstantContextForExpressionImpl(element, initializer);
      }
    }
    applyConstantOffsets?.perform();
  }
}

class TypeAliasElementLinkedData
    extends ElementLinkedData<TypeAliasElementImpl> {
  ApplyConstantOffsets? applyConstantOffsets;

  TypeAliasElementLinkedData({
    required Reference reference,
    required LibraryReader libraryReader,
    required CompilationUnitElementImpl unitElement,
    required int offset,
  }) : super(reference, libraryReader, unitElement, offset);

  @override
  void _clearLinkedDataOnRead(TypeAliasElementImpl element) {
    element.linkedData = null;
  }

  @override
  void _read(element, reader) {
    element.metadata = reader._readAnnotationList(
      unitElement: unitElement,
    );
    _readTypeParameters(reader, element.typeParameters);
    element.aliasedElement = reader._readAliasedElement(unitElement);
    element.aliasedType = reader.readRequiredType();
    applyConstantOffsets?.perform();
  }
}

/// Information that we need to know about each library before reading it,
/// and without reading it.
///
/// Specifically, the [offset] allows us to know the location of each library,
/// so that when we need to read this library, we know where it starts without
/// reading previous libraries.
class _LibraryHeader {
  final Uri uri;
  final int offset;

  /// We don't read class members when reading libraries, by performance
  /// reasons - in many cases only some classes of a library are used. But
  /// we need to know how much data to skip for each class.
  final Uint32List classMembersLengths;

  _LibraryHeader({
    required this.uri,
    required this.offset,
    required this.classMembersLengths,
  });
}

class _ReferenceReader {
  final LinkedElementFactory elementFactory;
  final SummaryDataReader _reader;
  late final Uint32List _parents;
  late final Uint32List _names;
  late final List<Reference?> _references;

  _ReferenceReader(this.elementFactory, this._reader, int offset) {
    _reader.offset = offset;
    _parents = _reader.readUInt30List();
    _names = _reader.readUInt30List();
    assert(_parents.length == _names.length);

    _references = List.filled(_names.length, null);
  }

  Reference referenceOfIndex(int index) {
    var reference = _references[index];
    if (reference != null) {
      return reference;
    }

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var nameIndex = _names[index];
    var name = _reader.stringOfIndex(nameIndex);

    var parentIndex = _parents[index];
    var parent = referenceOfIndex(parentIndex);

    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }
}
