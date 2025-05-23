// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ZONE_H_
#define RUNTIME_VM_ZONE_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/handles.h"
#include "vm/memory_region.h"
#include "vm/thread_state.h"

namespace dart {

// Zones support very fast allocation of small chunks of memory. The
// chunks cannot be deallocated individually, but instead zones
// support deallocating all chunks in one fast operation.

class Zone {
 public:
  // Allocate an array sized to hold 'len' elements of type
  // 'ElementType'.  Checks for integer overflow when performing the
  // size computation.
  template <class ElementType>
  inline ElementType* Alloc(intptr_t len);

  // Allocates an array sized to hold 'len' elements of type
  // 'ElementType'.  The new array is initialized from the memory of
  // 'old_array' up to 'old_len'.
  template <class ElementType>
  inline ElementType* Realloc(ElementType* old_array,
                              intptr_t old_len,
                              intptr_t new_len);

  // Allocates 'size' bytes of memory in the zone; expands the zone by
  // allocating new segments of memory on demand using 'new'.
  //
  // It is preferred to use Alloc<T>() instead, as that function can
  // check for integer overflow.  If you use AllocUnsafe, you are
  // responsible for avoiding integer overflow yourself.
  inline uword AllocUnsafe(intptr_t size);

  // Make a copy of the string in the zone allocated area.
  char* MakeCopyOfString(const char* str);

  // Make a copy of the first n characters of a string in the zone
  // allocated area.
  char* MakeCopyOfStringN(const char* str, intptr_t len);

  // Concatenate strings |a| and |b|. |a| may be nullptr. If |a| is not nullptr,
  // |join| will be inserted between |a| and |b|.
  char* ConcatStrings(const char* a, const char* b, char join = ',');

  // TODO(zra): Remove these calls and replace them with calls to OS::SCreate
  // and OS::VSCreate.
  // These calls are deprecated. Do not add further calls to these functions.
  // instead use OS::SCreate and OS::VSCreate.
  // Make a zone-allocated string based on printf format and args.
  char* PrintToString(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  char* VPrint(const char* format, va_list args);

  // Compute the total size of allocations in this zone.
  uintptr_t SizeInBytes() const;

  // Computes the amount of space used by the zone.
  uintptr_t CapacityInBytes() const;

  // Dump the current allocated sizes in the zone object.
  void Print() const;

  // Structure for managing handles allocation.
  VMHandles* handles() { return &handles_; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  Zone* previous() const { return previous_; }

  bool ContainsNestedZone(Zone* other) const {
    while (other != nullptr) {
      if (this == other) return true;
      other = other->previous_;
    }
    return false;
  }

  // All pointers returned from AllocateUnsafe() and New() have this alignment.
  static constexpr intptr_t kAlignment = kDoubleSize;

  static void Init();
  static void Cleanup();

  static void ClearCache();
  static intptr_t Size() { return total_size_; }

  // Allow templated containers to check if this allocator supports
  // freeing individual allocations.
  static constexpr bool kSupportsFreeingIndividualAllocations = false;

 private:
  Zone();
  ~Zone();  // Delete all memory associated with the zone.

  // Default initial chunk size.
  static constexpr intptr_t kInitialChunkSize = 128;

  // Default segment size.
  static constexpr intptr_t kSegmentSize = 64 * KB;

  // Zap value used to indicate deleted zone area (debug purposes).
  static constexpr unsigned char kZapDeletedByte = 0x42;

  // Zap value used to indicate uninitialized zone area (debug purposes).
  static constexpr unsigned char kZapUninitializedByte = 0xab;

  // Total size of current zone segments.
  static RelaxedAtomic<intptr_t> total_size_;

  // Expand the zone to accommodate an allocation of 'size' bytes.
  uword AllocateExpand(intptr_t size);

  // Allocate a large segment.
  uword AllocateLargeSegment(intptr_t size);

  // Insert zone into zone chain, after current_zone.
  void Link(Zone* current_zone) { previous_ = current_zone; }

  // Delete all objects and free all memory allocated in the zone.
  void Reset();

  // Does not actually free any memory. Enables templated containers like
  // BaseGrowableArray to use different allocators.
  template <class ElementType>
  void Free(ElementType* old_array, intptr_t len) {
#ifdef DEBUG
    if (len > 0) {
      ASSERT(old_array != nullptr);
      memset(static_cast<void*>(old_array), kZapUninitializedByte,
             len * sizeof(ElementType));
    }
#endif
  }

  // Overflow check (FATAL) for array length.
  template <class ElementType>
  static inline void CheckLength(intptr_t len);

  // The free region in the current (head) segment or the initial buffer is
  // represented as the half-open interval [position, limit). The 'position'
  // variable is guaranteed to be aligned as dictated by kAlignment.
  uword position_;
  uword limit_;

  // Zone segments are internal data structures used to hold information
  // about the memory segmentations that constitute a zone. The entire
  // implementation is in zone.cc.
  class Segment;

  // Total size of all allocations in this zone.
  intptr_t size_ = 0;

  // Total size of all segments in [head_].
  intptr_t small_segment_capacity_ = 0;

  // List of all segments allocated in this zone; may be nullptr.
  Segment* segments_;

  // Used for chaining zones in order to allow unwinding of stacks.
  Zone* previous_;

  // Structure for managing handles allocation.
  VMHandles handles_;

  // This buffer is used for allocation before any segments.
  // This would act as the initial stack allocated chunk so that we don't
  // end up calling malloc/free on zone scopes that allocate less than
  // kChunkSize
  COMPILE_ASSERT(kAlignment <= 8);
  ALIGN8 uint8_t buffer_[kInitialChunkSize];

  friend class StackZone;
  friend class ApiZone;
  friend class AllocOnlyStackZone;
  template <typename T, typename B, typename Allocator>
  friend class BaseGrowableArray;
  template <typename T, typename B, typename Allocator>
  friend class BaseDirectChainedHashMap;
  DISALLOW_COPY_AND_ASSIGN(Zone);
};

class StackZone : public StackResource {
 public:
  // Create an empty zone and set is at the current zone for the Thread.
  explicit StackZone(ThreadState* thread);

  // Delete all memory associated with the zone.
  virtual ~StackZone();

  // DART_USE_ABSL encodes the use of fibers in the Dart VM for threading,
#if defined(DART_USE_ABSL)
  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  uintptr_t SizeInBytes() const { return zone_->SizeInBytes(); }

  // Computes the used space in the zone.
  intptr_t CapacityInBytes() const { return zone_->CapacityInBytes(); }

  Zone* GetZone() { return zone_; }
#else
  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  uintptr_t SizeInBytes() const { return zone_.SizeInBytes(); }

  // Computes the used space in the zone.
  intptr_t CapacityInBytes() const { return zone_.CapacityInBytes(); }

  Zone* GetZone() { return &zone_; }
#endif  // defined(DART_USE_ABSL)

 private:
#if defined(DART_USE_ABSL)
  // When fibers are used we have to make do with a smaller stack size and hence
  // the first zone is allocated instead of being a stack resource.
  Zone* zone_;
#else
  // For regular configurations that have larger stack sizes it is ok to
  // have the first zone be a stack resource, avoids the overhead of a malloc
  // call for every stack zone creation.
  Zone zone_;
#endif  // defined(DART_USE_ABSL)

  template <typename T>
  friend class GrowableArray;
  template <typename T>
  friend class ZoneGrowableArray;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StackZone);
};

class AllocOnlyStackZone : public ValueObject {
 public:
  AllocOnlyStackZone() : zone_() {}
  ~AllocOnlyStackZone() {
    // This zone is not linked into the thread, so any handles would not be
    // visited.
    ASSERT(zone_.handles()->IsEmpty());
  }

  Zone* GetZone() { return &zone_; }

 private:
  Zone zone_;

  DISALLOW_COPY_AND_ASSIGN(AllocOnlyStackZone);
};

inline uword Zone::AllocUnsafe(intptr_t size) {
  ASSERT(size >= 0);
  // Round up the requested size to fit the alignment.
  if (size > (kIntptrMax - kAlignment)) {
    FATAL("Zone::Alloc: 'size' is too large: size=%" Pd "", size);
  }
  size = Utils::RoundUp(size, kAlignment);

  // Check if the requested size is available without expanding.
  uword result;
  intptr_t free_size = (limit_ - position_);
  if (free_size >= size) {
    result = position_;
    position_ += size;
    size_ += size;
  } else {
    result = AllocateExpand(size);
  }

  // Check that the result has the proper alignment and return it.
  ASSERT(Utils::IsAligned(result, kAlignment));
  return result;
}

template <class ElementType>
inline void Zone::CheckLength(intptr_t len) {
  const intptr_t kElementSize = sizeof(ElementType);
  if (len > (kIntptrMax / kElementSize)) {
    FATAL("Zone::Alloc: 'len' is too large: len=%" Pd ", kElementSize=%" Pd,
          len, kElementSize);
  }
}

template <class ElementType>
inline ElementType* Zone::Alloc(intptr_t len) {
  CheckLength<ElementType>(len);
  return reinterpret_cast<ElementType*>(AllocUnsafe(len * sizeof(ElementType)));
}

template <class ElementType>
inline ElementType* Zone::Realloc(ElementType* old_data,
                                  intptr_t old_len,
                                  intptr_t new_len) {
  CheckLength<ElementType>(new_len);
  const intptr_t kElementSize = sizeof(ElementType);
  if (old_data != nullptr) {
    uword old_end =
        reinterpret_cast<uword>(old_data) + (old_len * kElementSize);
    // Resize existing allocation if nothing was allocated in between...
    if (Utils::RoundUp(old_end, kAlignment) == position_) {
      uword new_end =
          reinterpret_cast<uword>(old_data) + (new_len * kElementSize);
      // ...and there is sufficient space.
      if (new_end <= limit_) {
        position_ = Utils::RoundUp(new_end, kAlignment);
        size_ += static_cast<intptr_t>(new_len - old_len);
        return old_data;
      }
    }
    if (new_len <= old_len) {
      return old_data;
    }
  }
  ElementType* new_data = Alloc<ElementType>(new_len);
  if (old_data != nullptr) {
    memmove(reinterpret_cast<void*>(new_data),
            reinterpret_cast<void*>(old_data), old_len * kElementSize);
  }
  return new_data;
}

}  // namespace dart

#endif  // RUNTIME_VM_ZONE_H_
