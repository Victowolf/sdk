// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuntimeTypeEqualityTypeTest);
  });
}

@reflectiveTest
class RuntimeTypeEqualityTypeTest extends AbstractTypeSystemTest
    with StringTypes {
  @override
  void setUp() {
    super.setUp();
    defineStringTypes();
  }

  test_dynamic() {
    _equal(dynamicType, dynamicType);
    _notEqual(dynamicType, voidNone);
    _notEqual(dynamicType, intNone);

    _notEqual(dynamicType, neverNone);
    _notEqual(dynamicType, neverQuestion);
  }

  test_functionType_parameters() {
    void check(
      FormalParameterElementImpl T1_parameter,
      FormalParameterElementImpl T2_parameter,
      bool expected,
    ) {
      var T1 = functionTypeNone(
        returnType: voidNone,
        formalParameters: [T1_parameter],
      );
      var T2 = functionTypeNone(
        returnType: voidNone,
        formalParameters: [T2_parameter],
      );
      _check(T1, T2, expected);
    }

    {
      void checkRequiredParameter(
        TypeImpl T1_type,
        TypeImpl T2_type,
        bool expected,
      ) {
        check(
          requiredParameter(type: T1_type),
          requiredParameter(type: T2_type),
          expected,
        );
      }

      checkRequiredParameter(intNone, intNone, true);
      checkRequiredParameter(intNone, intQuestion, false);

      checkRequiredParameter(intQuestion, intNone, false);
      checkRequiredParameter(intQuestion, intQuestion, true);

      check(
        requiredParameter(type: intNone, name: 'a'),
        requiredParameter(type: intNone, name: 'b'),
        true,
      );

      check(
        requiredParameter(type: intNone),
        positionalParameter(type: intNone),
        false,
      );

      check(
        requiredParameter(type: intNone),
        namedParameter(type: intNone, name: 'a'),
        false,
      );

      check(
        requiredParameter(type: intNone),
        namedRequiredParameter(type: intNone, name: 'a'),
        false,
      );
    }

    {
      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'a'),
        true,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: boolNone, name: 'a'),
        false,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'b'),
        false,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'a'),
        false,
      );
    }

    {
      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'a'),
        true,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: boolNone, name: 'a'),
        false,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'b'),
        false,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'a'),
        false,
      );
    }
  }

  test_functionType_returnType() {
    void check(
      TypeImpl T1_returnType,
      TypeImpl T2_returnType,
      bool expected,
    ) {
      var T1 = functionTypeNone(
        returnType: T1_returnType,
      );
      var T2 = functionTypeNone(
        returnType: T2_returnType,
      );
      _check(T1, T2, expected);
    }

    check(intNone, intNone, true);
    check(intNone, intQuestion, false);
  }

  test_functionType_typeParameters() {
    {
      var T1_T = typeParameter('T', bound: numNone);
      _check(
        functionTypeNone(
          typeParameters: [T1_T],
          returnType: voidNone,
        ),
        functionTypeNone(
          returnType: voidNone,
        ),
        false,
      );
    }

    {
      var T1_T = typeParameter('T', bound: numNone);
      var T2_U = typeParameter('U');
      _check(
        functionTypeNone(
          typeParameters: [T1_T],
          returnType: voidNone,
        ),
        functionTypeNone(
          typeParameters: [T2_U],
          returnType: voidNone,
        ),
        false,
      );
    }

    {
      var T1_T = typeParameter('T');
      var T2_U = typeParameter('U');
      _check(
        functionTypeNone(
          typeParameters: [T1_T],
          returnType: typeParameterTypeNone(T1_T),
          formalParameters: [
            requiredParameter(
              type: typeParameterTypeNone(T1_T),
            )
          ],
        ),
        functionTypeNone(
          typeParameters: [T2_U],
          returnType: typeParameterTypeNone(T2_U),
          formalParameters: [
            requiredParameter(
              type: typeParameterTypeNone(T2_U),
            )
          ],
        ),
        true,
      );
    }
  }

  test_interfaceType() {
    _notEqual(intNone, boolNone);

    _equal(intNone, intNone);
    _notEqual(intNone, intQuestion);

    _notEqual(intQuestion, intNone);
    _equal(intQuestion, intQuestion);
  }

  test_interfaceType_typeArguments() {
    void equal(TypeImpl T1, TypeImpl T2) {
      _equal(listNone(T1), listNone(T2));
    }

    void notEqual(TypeImpl T1, TypeImpl T2) {
      _notEqual(listNone(T1), listNone(T2));
    }

    notEqual(intNone, boolNone);

    equal(intNone, intNone);
    notEqual(intNone, intQuestion);

    notEqual(intQuestion, intNone);
    equal(intQuestion, intQuestion);
  }

  test_never() {
    _equal(neverNone, neverNone);
    _notEqual(neverNone, neverQuestion);
    _notEqual(neverNone, intNone);

    _notEqual(neverQuestion, neverNone);
    _equal(neverQuestion, neverQuestion);
    _notEqual(neverQuestion, intNone);
    _equal(neverQuestion, nullNone);
  }

  test_norm() {
    _equal(futureOrNone(objectNone), objectNone);
    _equal(futureOrNone(neverNone), futureNone(neverNone));
    _equal(neverQuestion, nullNone);
  }

  test_recordType_andNot() {
    _notEqual2('(int,)', 'dynamic');
    _notEqual2('(int,)', 'int');
    _notEqual2('(int,)', 'void');
  }

  test_recordType_differentShape() {
    _notEqual2('(int,)', '(int, int)');
    _notEqual2('(int,)', '({int f1})');
    _notEqual2('({int f1})', '({int f2})');
    _notEqual2('({int f1})', '({int f1, int f2})');
  }

  test_recordType_sameShape_named() {
    _equal2('({int f1})', '({int f1})');
    _notEqual2('({int f1})', '({int? f1})');

    _notEqual2('({int f1})', '({double f1})');
  }

  test_recordType_sameShape_positional() {
    _equal2('(int,)', '(int,)');
    _notEqual2('(int,)', '(int?,)');

    _notEqual2('(int,)', '(double,)');
  }

  test_void() {
    _equal(voidNone, voidNone);
    _notEqual(voidNone, dynamicType);
    _notEqual(voidNone, intNone);

    _notEqual(voidNone, neverNone);
    _notEqual(voidNone, neverQuestion);
  }

  void _check(TypeImpl T1, TypeImpl T2, bool expected) {
    bool result;

    result = typeSystem.runtimeTypesEqual(T1, T2);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${typeString(T1)}
T2: ${typeString(T2)}
''');
    }

    result = typeSystem.runtimeTypesEqual(T2, T1);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${typeString(T1)}
T2: ${typeString(T2)}
''');
    }
  }

  void _equal(TypeImpl T1, TypeImpl T2) {
    _check(T1, T2, true);
  }

  void _equal2(String T1, String T2) {
    _equal(
      typeOfString(T1),
      typeOfString(T2),
    );
  }

  void _notEqual(TypeImpl T1, TypeImpl T2) {
    _check(T1, T2, false);
  }

  void _notEqual2(String T1, String T2) {
    _notEqual(
      typeOfString(T1),
      typeOfString(T2),
    );
  }
}
