// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/a70adce28e53ff8bb3445fe96f3f1be951d8a417/runtime/vm/isolate_reload_test.cc#L5757

class A {}

class B extends A {}

A value = init();

init() => B();

helper() {
  try {
    return value.toString();
  } catch (e) {
    return e.toString();
  }
}

Future<void> main() async {
  Expect.equals("Instance of 'B'", helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  Expect.contains("type 'B' is not a subtype of type 'A'", helper());
  Expect.equals(1, hotReloadGeneration);
}
