// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameters keep their names in the output.

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
class A { }
class B { }

main() {
  A();
  B();
}
""";

const String TEST_TWO = r"""
class A { }
class B extends A { }

main() {
  A();
  B();
  String c = '';
  print(c);
}
""";

const String TEST_THREE = r"""
class B extends A { }
class A { }

main() {
  String c = '';
  print(c);
  B();
  A();
}
""";

const String TEST_FOUR = r"""
var g = 0;
class A {
  @pragma('dart2js:noElision')
  var x = g++;
}

class B extends A {
  @pragma('dart2js:noElision')
  var y = g++;
  @pragma('dart2js:noElision')
  var z = g++;
}

main() {
  B();
}
""";

const String TEST_FIVE = r"""
class A {
  @pragma('dart2js:noElision')
  var a;
  A(a) : this.a = a {}
}

main() {
  A(3);
}
""";

twoClasses() async {
  String generated = await compileAll(TEST_ONE);
  Expect.isTrue(generated.contains('A: function A()'));
  Expect.isTrue(generated.contains('B: function B()'));
}

subClass() async {
  checkOutput(String generated) {
    Expect.isTrue(
      generated.contains(RegExp(r'_inherit\([$A-Z]+\.B, [$A-Z]+\.A\)')),
    );
  }

  checkOutput(await compileAll(TEST_TWO));
  checkOutput(await compileAll(TEST_THREE));
}

fieldTest() async {
  String generated = await compileAll(TEST_FOUR);
  Expect.isTrue(
    generated.contains(
      RegExp(
        r'B: function B\(t0, t1, t2\) {'
        r'\s*this.y = t0;'
        r'\s*this.z = t1;'
        r'\s*this.x = t2;',
      ),
    ),
  );
}

constructor1() async {
  String generated = await compileAll(TEST_FIVE);
  Expect.isTrue(
    generated.contains(new RegExp(r"new [$A-Z]+\.A\(a\);")),
    '--------------------\n$generated\n',
  );
}

main() {
  runTests() async {
    await twoClasses();
    await subClass();
    await fieldTest();
    await constructor1();
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
