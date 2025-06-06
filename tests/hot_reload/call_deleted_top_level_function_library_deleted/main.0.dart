// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/13f5fc6b168d8b6e5843d17fb9ba77f1343a7dfe/runtime/vm/isolate_reload_test.cc#L2825

import 'test-lib.dart';

var retained;
helper() {
  retained = () => deleted();
  return retained();
}

Future<void> main() async {
  Expect.equals('hello', helper());
  await hotReload();

  // VM: What actually happens because we don't re-search imported libraries.
  Expect.equals('hello', helper());

  // VM: What should happen and what did happen with the old VM frontend:
  // Expect.throws<NoSuchMethodError>(
  //   helper,
  //   (error) => error.toString().contains('deleted'),
  // );
}
