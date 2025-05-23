// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmark for ffi struct field stores and loads.
//
// Only tests a single field because the FfiMemory benchmark already tests loads
// and stores of different field sizes.

import 'dart:ffi';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ffi/ffi.dart';

//
// Struct field store (plus Pointer elementAt and load).
//

void doStoreInt32(Pointer<VeryLargeStruct> pointer, int length) {
  for (int i = 0; i < length; i++) {
    pointer[i].c = 1;
  }
}

//
// Struct field load (plus Pointer elementAt and load).
//

int doLoadInt32(Pointer<VeryLargeStruct> pointer, int length) {
  int x = 0;
  for (int i = 0; i < length; i++) {
    x += pointer[i].c;
  }
  return x;
}

//
// Benchmark fixture.
//

// Number of repeats: 1000
//  * CPU: Intel(R) Xeon(R) Gold 6154
//    * Architecture: x64
//      * 150000 - 465000 us (without optimizations)
//      * 14 - ??? us (expected with optimizations, on par with typed data)
const N = 1000;

class FieldLoadStore extends BenchmarkBase {
  Pointer<VeryLargeStruct> pointer = nullptr;
  FieldLoadStore() : super('FfiStruct.FieldLoadStore');

  @override
  void setup() => pointer = calloc(N);
  @override
  void teardown() => calloc.free(pointer);

  @override
  void run() {
    doStoreInt32(pointer, N);
    final int x = doLoadInt32(pointer, N);
    if (x != N) {
      throw Exception('$name: Unexpected result: $x');
    }
  }
}

//
// Main driver.
//

void main(List<String> args) {
  final benchmarks = [FieldLoadStore.new];

  final filter = args.firstOrNull;
  for (var constructor in benchmarks) {
    final benchmark = constructor();
    if (filter == null || benchmark.name.contains(filter)) {
      benchmark.report();
    }
  }
}

//
// Test struct.
//
final class VeryLargeStruct extends Struct {
  @Int8()
  external int a;

  @Int16()
  external int b;

  @Int32()
  external int c;

  @Int64()
  external int d;

  @Uint8()
  external int e;

  @Uint16()
  external int f;

  @Uint32()
  external int g;

  @Uint64()
  external int h;

  @IntPtr()
  external int i;

  @Double()
  external double j;

  @Float()
  external double k;

  external Pointer<VeryLargeStruct> parent;

  @IntPtr()
  external int numChildren;

  external Pointer<VeryLargeStruct> children;

  @Int8()
  external int smallLastField;
}
