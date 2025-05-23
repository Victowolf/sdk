// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'ffi_test_helpers.dart';

void main() {
  testPointerBasic();
  testPointerFromPointer();
  testPointerPointerArithmetic();
  testPointerPointerArithmeticSizes();
  testPointerAllocateZero();
  testPointerCast();
  testCastGeneric();
  testCastGeneric2();
  testCastNativeType();
  testCondensedNumbersInt8();
  testCondensedNumbersFloat();
  testRangeInt8();
  testRangeUint8();
  testRangeInt16();
  testRangeUint16();
  testRangeInt32();
  testRangeUint32();
  testRangeInt64();
  testRangeUint64();
  testRangeIntPtr();
  testFloat();
  testDouble();
  testVoid();
  testPointerPointer();
  testPointerPointerNull();
  testSizeOf();
  testPointerChain(100);
  testToString();
  testEquality();
  testDynamicInvocation();
  testMemoryAddressTruncation();
  testNullptrCast();
}

void testPointerBasic() {
  Pointer<Int64> p = calloc();
  p.value = 42;
  Expect.equals(42, p.value);
  calloc.free(p);
}

void testPointerFromPointer() {
  Pointer<Int64> p = calloc();
  p.value = 1337;
  int ptr = p.address;
  Pointer<Int64> p2 = Pointer.fromAddress(ptr);
  Expect.equals(1337, p2.value);
  calloc.free(p);
}

void testPointerPointerArithmetic() {
  Pointer<Int64> p = calloc(2);
  Pointer<Int64> p2 = p + 1;
  p2.value = 100;
  Pointer<Int64> p3 = p.offsetBy(8);
  Expect.equals(100, p3.value);
  calloc.free(p);

  p = calloc(2);
  Pointer<Int64> p4 = p + 1;
  p4.value = 100;
  Pointer<Int64> p5 = p.offsetBy(8);
  Expect.equals(100, p5.value);
  calloc.free(p);
}

void testPointerPointerArithmeticSizes() {
  Pointer<Int64> p = calloc(2);
  Pointer<Int64> p2 = p + 1;
  int addr = p.address;
  Expect.equals(addr + 8, p2.address);
  calloc.free(p);

  Pointer<Int32> p3 = calloc(2);
  Pointer<Int32> p4 = p3 + 1;
  addr = p3.address;
  Expect.equals(addr + 4, p4.address);
  calloc.free(p3);

  p = calloc(2);
  p2 = p + 1;
  addr = p.address;
  Expect.equals(addr + 8, p2.address);
  calloc.free(p);

  Pointer<Int32> p5 = calloc(2);
  Pointer<Int32> p6 = p5 + 1;
  addr = p5.address;
  Expect.equals(addr + 4, p6.address);
  calloc.free(p5);
}

void testPointerAllocateZero() {
  // > If size is 0, either a null pointer or a unique pointer that can be
  // > successfully passed to calloc.free() shall be returned.
  // http://pubs.opengroup.org/onlinepubs/009695399/functions/calloc.html
  //
  // Null pointer throws a Dart exception.
  bool returnedNullPointer = false;
  Pointer<Int8> p = nullptr;
  try {
    p = calloc<Int8>(0);
  } on Exception {
    returnedNullPointer = true;
  }
  if (!returnedNullPointer) {
    calloc.free(p);
  }
}

void testPointerCast() {
  Pointer<Int64> p = calloc();
  p.cast<Int32>(); // gets the correct type args back
  calloc.free(p);
}

void testCastGeneric() {
  Pointer<T> generic<T extends NativeType>(Pointer<Int16> p) {
    return p.cast();
  }

  Pointer<Int16> p = calloc();
  generic(p);
  calloc.free(p);
}

void testCastGeneric2() {
  Pointer<Int64> generic<T extends NativeType>(Pointer<T> p) {
    return p.cast();
  }

  Pointer<Int16> p = calloc();
  // ignore: unused_local_variable
  Pointer<Int64> p2 = generic(p);
  calloc.free(p);
}

void testCastNativeType() {
  Pointer<Int64> p = calloc();
  p.cast<Pointer>();
  calloc.free(p);
}

void testCondensedNumbersInt8() {
  Pointer<Int8> p = calloc(8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p[i] = i * 3;
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(i * 3, p[i]);
  }
  calloc.free(p);
}

void testCondensedNumbersFloat() {
  Pointer<Float> p = calloc(8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p[i] = 1.511366173271439e-13;
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(1.511366173271439e-13, p[i]);
  }
  calloc.free(p);
}

void testRangeInt8() {
  Pointer<Int8> p = calloc();
  p.value = 127;
  Expect.equals(127, p.value);
  p.value = -128;
  Expect.equals(-128, p.value);

  Expect.equals(0x0000000000000080, 128);
  Expect.equals(0xFFFFFFFFFFFFFF80, -128);
  p.value = 128;
  Expect.equals(-128, p.value); // truncated and sign extended

  Expect.equals(0xFFFFFFFFFFFFFF7F, -129);
  Expect.equals(0x000000000000007F, 127);
  p.value = -129;
  Expect.equals(127, p.value); // truncated
  calloc.free(p);
}

void testRangeUint8() {
  Pointer<Uint8> p = calloc();
  p.value = 255;
  Expect.equals(255, p.value);
  p.value = 0;
  Expect.equals(0, p.value);

  Expect.equals(0x0000000000000000, 0);
  Expect.equals(0x0000000000000100, 256);
  p.value = 256;
  Expect.equals(0, p.value); // truncated

  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  Expect.equals(0x00000000000000FF, 255);
  p.value = -1;
  Expect.equals(255, p.value); // truncated
  calloc.free(p);
}

void testRangeInt16() {
  Pointer<Int16> p = calloc();
  p.value = 0x7FFF;
  Expect.equals(0x7FFF, p.value);
  p.value = -0x8000;
  Expect.equals(-0x8000, p.value);
  p.value = 0x8000;
  Expect.equals(0xFFFFFFFFFFFF8000, p.value); // truncated and sign extended
  p.value = -0x8001;
  Expect.equals(0x7FFF, p.value); // truncated
  calloc.free(p);
}

void testRangeUint16() {
  Pointer<Uint16> p = calloc();
  p.value = 0xFFFF;
  Expect.equals(0xFFFF, p.value);
  p.value = 0;
  Expect.equals(0, p.value);
  p.value = 0x10000;
  Expect.equals(0, p.value); // truncated
  p.value = -1;
  Expect.equals(0xFFFF, p.value); // truncated
  calloc.free(p);
}

void testRangeInt32() {
  Pointer<Int32> p = calloc();
  p.value = 0x7FFFFFFF;
  Expect.equals(0x7FFFFFFF, p.value);
  p.value = -0x80000000;
  Expect.equals(-0x80000000, p.value);
  p.value = 0x80000000;
  Expect.equals(0xFFFFFFFF80000000, p.value); // truncated and sign extended
  p.value = -0x80000001;
  Expect.equals(0x7FFFFFFF, p.value); // truncated
  calloc.free(p);
}

void testRangeUint32() {
  Pointer<Uint32> p = calloc();
  p.value = 0xFFFFFFFF;
  Expect.equals(0xFFFFFFFF, p.value);
  p.value = 0;
  Expect.equals(0, p.value);
  p.value = 0x100000000;
  Expect.equals(0, p.value); // truncated
  p.value = -1;
  Expect.equals(0xFFFFFFFF, p.value); // truncated
  calloc.free(p);
}

void testRangeInt64() {
  Pointer<Int64> p = calloc();
  p.value = 0x7FFFFFFFFFFFFFFF; // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.value);
  p.value = -0x8000000000000000; // -2 ^ 63
  Expect.equals(-0x8000000000000000, p.value);
  calloc.free(p);
}

void testRangeUint64() {
  Pointer<Uint64> p = calloc();
  p.value = 0x7FFFFFFFFFFFFFFF; // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.value);
  p.value = -0x8000000000000000; // -2 ^ 63 interpreted as 2 ^ 63
  Expect.equals(-0x8000000000000000, p.value);

  // Dart allows interpreting bits both signed and unsigned
  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  p.value = -1; // -1 interpreted as 2 ^ 64 - 1
  Expect.equals(-1, p.value);
  Expect.equals(0xFFFFFFFFFFFFFFFF, p.value);
  calloc.free(p);
}

void testRangeIntPtr() {
  Pointer<IntPtr> p = calloc();
  int pAddr = p.address;
  p.value = pAddr; // its own address should fit
  p.value = 0x7FFFFFFF; // and 32 bit addresses should fit
  Expect.equals(0x7FFFFFFF, p.value);
  p.value = -0x80000000;
  Expect.equals(-0x80000000, p.value);
  calloc.free(p);
}

void testFloat() {
  Pointer<Float> p = calloc();
  p.value = 1.511366173271439e-13;
  Expect.equals(1.511366173271439e-13, p.value);
  p.value = 1.4260258159703532e-105; // float does not have enough precision
  Expect.notEquals(1.4260258159703532e-105, p.value);
  calloc.free(p);
}

void testDouble() {
  Pointer<Double> p = calloc();
  p.value = 1.4260258159703532e-105;
  Expect.equals(1.4260258159703532e-105, p.value);
  calloc.free(p);
}

void testVoid() {
  Pointer<IntPtr> p1 = calloc();
  Pointer<Void> p2 = p1.cast(); // make this dart pointer opaque
  p2.address; // we can print the address
  calloc.free(p2);
}

void testPointerPointer() {
  Pointer<Int16> p = calloc();
  p.value = 17;
  Pointer<Pointer<Int16>> p2 = calloc();
  p2.value = p;
  Expect.equals(17, p2.value.value);
  calloc.free(p2);
  calloc.free(p);
}

void testPointerPointerNull() {
  Pointer<Pointer<Int8>> pointerToPointer = calloc();
  Pointer<Int8> value = nullptr;
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.equals(value, nullptr);
  value = calloc();
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.isNotNull(value);
  calloc.free(value);
  value = nullptr;
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.equals(value, nullptr);
  calloc.free(pointerToPointer);
}

void testSizeOf() {
  Expect.equals(1, sizeOf<Int8>());
  Expect.equals(2, sizeOf<Int16>());
  Expect.equals(4, sizeOf<Int32>());
  Expect.equals(8, sizeOf<Int64>());
  Expect.equals(1, sizeOf<Uint8>());
  Expect.equals(2, sizeOf<Uint16>());
  Expect.equals(4, sizeOf<Uint32>());
  Expect.equals(8, sizeOf<Uint64>());
  Expect.equals(true, 4 == sizeOf<IntPtr>() || 8 == sizeOf<IntPtr>());
  Expect.equals(4, sizeOf<Float>());
  Expect.equals(8, sizeOf<Double>());
}

// note: stack overflows at around 15k calls
void testPointerChain(int length) {
  void createChain(Pointer<IntPtr> head, int length, int value) {
    if (length == 0) {
      head.value = value;
      return;
    }
    Pointer<IntPtr> next = calloc();
    head.value = next.address;
    createChain(next, length - 1, value);
  }

  int getChainValue(Pointer<IntPtr> head, int length) {
    if (length == 0) {
      return head.value;
    }
    Pointer<IntPtr> next = Pointer.fromAddress(head.value);
    return getChainValue(next, length - 1);
  }

  void freeChain(Pointer<IntPtr> head, int length) {
    Pointer<IntPtr> next = Pointer.fromAddress(head.value);
    calloc.free(head);
    if (length == 0) {
      return;
    }
    freeChain(next, length - 1);
  }

  Pointer<IntPtr> head = calloc();
  createChain(head, length, 512);
  int tailValue = getChainValue(head, length);
  Expect.equals(512, tailValue);
  freeChain(head, length);
}

void testToString() {
  Pointer<Int16> p = calloc();
  Expect.stringEquals("Pointer: address=0x", p.toString().substring(0, 19));
  calloc.free(p);
  Pointer<Int64> p2 = Pointer.fromAddress(0x123abc);
  Expect.stringEquals("Pointer: address=0x123abc", p2.toString());
}

void testEquality() {
  Pointer<Int8> p = Pointer.fromAddress(12345678);
  Pointer<Int8> p2 = Pointer.fromAddress(12345678);
  Expect.equals(p, p2);
  Expect.equals(p.hashCode, p2.hashCode);
  Pointer<Int16> p3 = p.cast();
  Expect.equals(p, p3);
  Expect.equals(p.hashCode, p3.hashCode);
  Pointer<Int8> p4 = p.offsetBy(1337);
  Expect.notEquals(p, p4);
}

typedef Int8UnOp = Int8 Function(Int8);

void testDynamicInvocation() {
  dynamic p = calloc<Int8>();
  Expect.throws(() {
    p.value;
  });
  Expect.throws(() => p.value = 1);
  Expect.throws(() => p + 5);
  Expect.throws(() => p += 5);
  p.address;
  p.cast<Int16>();
  calloc.free(p);
}

final nullableInt64ElementAt1 = ffiTestFunctions.lookupFunction<
  Pointer<Int64> Function(Pointer<Int64>),
  Pointer<Int64> Function(Pointer<Int64>)
>("NullableInt64ElemAt1");

void testNullptrCast() {
  Pointer<Int64> ptr = nullptr;
  ptr = nullableInt64ElementAt1(ptr);
  Expect.equals(ptr, nullptr);
}

void testMemoryAddressTruncation() {
  const int kIgnoreBytesPositive = 0x1122334400000000;
  const int kIgnoreBytesNegative = 0xffddccbb00000000;
  if (sizeOf<IntPtr>() == 4) {
    final p1 = Pointer<Int8>.fromAddress(123);
    final p2 = Pointer<Int8>.fromAddress(123 + kIgnoreBytesPositive);
    final p3 = Pointer<Int8>.fromAddress(123 + kIgnoreBytesNegative);
    Expect.equals(p1.address, p2.address);
    Expect.equals(p1, p2);
    Expect.equals(p1.address, p3.address);
    Expect.equals(p1, p3);
  }
}
