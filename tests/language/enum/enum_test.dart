// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

enum Enum1 { _ }

enum Enum2 { A }

enum Enum3 { B, C }

// Don't format to preserve the trailing comma.
// dart format off
enum Enum4 { D, E, }
// dart format on

enum Enum5 { F, G, H }

enum _Enum6 { I, _J }

enum _IsNot { IsNot }

enum NamedName { name, address }

// Regression test for https://github.com/dart-lang/sdk/issues/33348
enum JSFunctionPrototype {
  length,
  prototype,
  __proto__,
  arguments,
  caller,
  callee,
  name,
  constructor,
  apply,
  bind,
  call,
}

void expectIs<T>(T t, bool Function(Object?) test) {
  Object? obj = t;
  Expect.isTrue(test(obj), '$obj is $T');
  Expect.isFalse(obj is _IsNot, '$obj is _IsNot');
  // test cast
  t = obj as T;
  Expect.throwsTypeError(() => obj as _IsNot, '$obj as _IsNot');
}

main() {
  expectIs(Enum1._, (e) => e is Enum1);
  expectIs(Enum2.A, (e) => e is Enum2);
  expectIs(Enum3.B, (e) => e is Enum3);
  expectIs(Enum4.E, (e) => e is Enum4);
  expectIs(Enum5.G, (e) => e is Enum5);

  Expect.equals('Enum1._', Enum1._.toString());
  Expect.equals(0, Enum1._.index);
  Expect.listEquals([Enum1._], Enum1.values);
  Enum1.values.forEach(test1);

  Expect.equals('Enum2.A', Enum2.A.toString());
  Expect.equals(0, Enum2.A.index);
  Expect.listEquals([Enum2.A], Enum2.values);
  Expect.identical(const <Enum2>[Enum2.A], Enum2.values);
  Enum2.values.forEach(test2);

  Expect.equals('Enum3.B', Enum3.B.toString());
  Expect.equals('Enum3.C', Enum3.C.toString());
  Expect.equals(0, Enum3.B.index);
  Expect.equals(1, Enum3.C.index);
  Expect.listEquals([Enum3.B, Enum3.C], Enum3.values);
  Enum3.values.forEach(test3);

  Expect.equals('Enum4.D', Enum4.D.toString());
  Expect.equals('Enum4.E', Enum4.E.toString());
  Expect.equals(0, Enum4.D.index);
  Expect.equals(1, Enum4.E.index);
  Expect.listEquals([Enum4.D, Enum4.E], Enum4.values);
  Enum4.values.forEach(test4);

  Expect.equals('Enum5.F', Enum5.F.toString());
  Expect.equals('Enum5.G', Enum5.G.toString());
  Expect.equals('Enum5.H', Enum5.H.toString());
  Expect.equals(0, Enum5.F.index);
  Expect.equals(1, Enum5.G.index);
  Expect.equals(2, Enum5.H.index);
  Expect.listEquals([Enum5.F, Enum5.G, Enum5.H], Enum5.values);
  Enum5.values.forEach(test5);

  Expect.equals('_Enum6.I', _Enum6.I.toString());
  Expect.equals('_Enum6._J', _Enum6._J.toString());

  for (var value in JSFunctionPrototype.values) {
    expectIs(value, (e) => e is JSFunctionPrototype);
  }
  Expect.equals(JSFunctionPrototype.length, JSFunctionPrototype.values[0]);

  // Enums implement Enum.
  Expect.type<Enum>(Enum1._);
  Enum enumValue = Enum1._;
  Expect.equals(0, enumValue.index);

  // Enum.compareByIndex orders enums correctly.
  var enumValues = [Enum5.G, Enum5.H, Enum5.F];
  for (var i = 0; i < 10; i++) {
    enumValues.sort(Enum.compareByIndex);
    enumValues.fold<int>(-1, (previousValue, element) {
      Expect.isTrue(previousValue < element.index, "$enumValues");
      return element.index;
    });
    enumValues.shuffle();
  }
  // Can be used at the type `Enum` to compare different enums.
  Expect.isTrue(Enum.compareByIndex<Enum>(Enum4.D, Enum5.H) < 0);
  Expect.isTrue(Enum.compareByIndex<Enum>(Enum4.E, Enum5.F) > 0);
  Expect.isTrue(Enum.compareByIndex<Enum>(Enum4.D, Enum5.F) == 0);

  Expect.equals("A", Enum2.A.name);
  Expect.equals("_", Enum1._.name);
  Expect.equals("name", EnumName(NamedName.name).name);

  Expect.identical(Enum2.A, Enum2.values.byName("A"));
  Expect.identical(Enum1._, Enum1.values.byName("_"));
  Expect.identical(NamedName.name, NamedName.values.byName("name"));

  var map = NamedName.values.asNameMap();
  Expect.type<Map<String, NamedName>>(map);
  Expect.identical(NamedName.name, map["name"]);
  Expect.identical(NamedName.address, map["address"]);
}

test1(Enum1 e) {
  int index;
  switch (e) {
    case Enum1._:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test2(Enum2 e) {
  int index;
  switch (e) {
    case Enum2.A:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test3(Enum3 e) {
  int index;
  switch (e) {
    case Enum3.C:
      index = 1;
      break;
    case Enum3.B:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test4(Enum4 e) {
  int index;
  switch (e) {
    case Enum4.D:
      index = 0;
      break;
    case Enum4.E:
      index = 1;
      break;
  }
  Expect.equals(e.index, index);
}

test5(Enum5 e) {
  int index;
  switch (e) {
    case Enum5.H:
      index = 2;
      break;
    case Enum5.F:
      index = 0;
      break;
    case Enum5.G:
      index = 1;
      break;
  }
  Expect.equals(e.index, index);
}
