// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  test1();
}

@pragma('dart2js:noInline')
test1() async {
  // This call is no longer on the stack when the error is thrown.
  await /*:test1*/ test2();
}

@pragma('dart2js:noInline')
test2() async {
  await null;
  /*1:test2*/
  throw '>ExceptionMarker<';
}
