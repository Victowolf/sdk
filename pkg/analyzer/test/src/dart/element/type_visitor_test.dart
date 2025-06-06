// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveTypeVisitorTest);
  });
}

@reflectiveTest
class RecursiveTypeVisitorTest extends AbstractTypeSystemTest with StringTypes {
  late final _MockRecursiveVisitor visitor;

  @override
  void setUp() {
    super.setUp();
    visitor = _MockRecursiveVisitor();
    defineStringTypes();
  }

  void test_callsDefaultBehavior() {
    expect(intNone.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_complex() {
    var T = typeParameter('T', bound: intNone);
    var K = typeParameter('K', bound: stringNone);
    var a = positionalParameter(type: numNone);
    var b = positionalParameter(type: doubleNone);
    var c = namedParameter(name: 'c', type: voidNone);
    var d = namedParameter(name: 'd', type: objectNone);
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [T, K],
        formalParameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([
      dynamicType,
      intNone,
      stringNone,
      numNone,
      doubleNone,
      voidNone,
      objectNone
    ]);
  }

  void test_functionType_positionalParameter() {
    var a = positionalParameter(type: intNone);
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [],
        formalParameters: [a],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_returnType() {
    var type = functionType(
        returnType: intNone,
        typeParameters: [],
        formalParameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_functionType_typeFormal_bound() {
    var T = typeParameter('T', bound: intNone);
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [T],
        formalParameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([dynamicType, intNone]);
  }

  void test_functionType_typeFormal_noBound() {
    var T = typeParameter('T');
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [T],
        formalParameters: [],
        nullabilitySuffix: NullabilitySuffix.none);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(dynamicType);
  }

  void test_interfaceType_typeParameter() {
    var type = typeProvider.listType(intNone);
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_interfaceType_typeParameters() {
    var type = typeProvider.mapType(intNone, stringNone);
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([intNone, stringNone]);
  }

  void test_interfaceType_typeParameters_nested() {
    var innerList = typeProvider.listType(intNone);
    var outerList = typeProvider.listType(innerList);
    expect(outerList.accept(visitor), true);
    visitor.assertVisitedType(intNone);
  }

  void test_recordType_named() {
    var type = typeOfString('({int f1, double f2})');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
    visitor.assertVisitedType(doubleNone);
  }

  void test_recordType_positional() {
    var type = typeOfString('(int, double)');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(intNone);
    visitor.assertVisitedType(doubleNone);
  }

  void test_stopVisiting_first() {
    var T = typeParameter('T', bound: intNone);
    var K = typeParameter('K', bound: stringNone);
    var a = positionalParameter(type: numNone);
    var b = positionalParameter(type: doubleNone);
    var c = namedParameter(name: 'c', type: voidNone);
    var d = namedParameter(name: 'd', type: objectNone);
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [T, K],
        formalParameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    visitor.stopOnType = dynamicType;
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes(
        [intNone, stringNone, numNone, doubleNone, voidNone, objectNone]);
  }

  void test_stopVisiting_halfway() {
    var T = typeParameter('T', bound: intNone);
    var K = typeParameter('K', bound: stringNone);
    var a = positionalParameter(type: numNone);
    var b = positionalParameter(type: doubleNone);
    var c = namedParameter(name: 'c', type: voidNone);
    var d = namedParameter(name: 'd', type: objectNone);
    var type = functionType(
        returnType: dynamicType,
        typeParameters: [T, K],
        formalParameters: [a, b, c, d],
        nullabilitySuffix: NullabilitySuffix.none);
    visitor.stopOnType = intNone;
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes([stringNone, voidNone, objectNone]);
  }

  void test_stopVisiting_nested() {
    var innerType = typeProvider.mapType(intNone, stringNone);
    var outerList = typeProvider.listType(innerType);
    visitor.stopOnType = intNone;
    expect(outerList.accept(visitor), false);
    visitor.assertNotVisitedType(stringNone);
  }

  void test_stopVisiting_nested_parent() {
    var innerTypeStop = typeProvider.listType(intNone);
    var innerTypeSkipped = typeProvider.listType(stringNone);
    var outerType = typeProvider.mapType(innerTypeStop, innerTypeSkipped);
    visitor.stopOnType = intNone;
    expect(outerType.accept(visitor), false);
    visitor.assertNotVisitedType(stringNone);
  }

  void test_stopVisiting_typeParameters() {
    var type = typeProvider.mapType(intNone, stringNone);
    visitor.stopOnType = intNone;
    expect(type.accept(visitor), false);
    visitor.assertVisitedType(intNone);
    visitor.assertNotVisitedType(stringNone);
  }
}

class _MockRecursiveVisitor extends RecursiveTypeVisitor {
  final Set<DartType> visitedTypes = {};
  DartType? stopOnType;

  _MockRecursiveVisitor() : super(includeTypeAliasArguments: false);

  void assertNotVisitedType(DartType type) {
    expect(visitedTypes, isNot(contains(type)));
  }

  void assertNotVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertNotVisitedType);

  void assertVisitedType(DartType type) {
    expect(visitedTypes, contains(type));
  }

  void assertVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertVisitedType);

  @override
  bool visitDartType(DartType type) {
    expect(type, isNotNull);
    visitedTypes.add(type);
    return type != stopOnType;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    visitedTypes.add(type);
    if (type == stopOnType) {
      return false;
    }
    return super.visitInterfaceType(type);
  }
}
