#include "rr.h"

namespace rr {
  void HeapStatistics::Init() {
    ClassBuilder("HeapStatistics").
      defineSingletonMethod("new", &initialize).
      defineMethod("total_heap_size", &total_heap_size).
      defineMethod("total_heap_size_executable", &total_heap_size_executable).
      defineMethod("total_physical_size", &total_physical_size).
      defineMethod("used_heap_size", &used_heap_size).
      defineMethod("heap_size_limit", &heap_size_limit).
      store(&Class);
  }
  VALUE HeapStatistics::initialize(VALUE self) {
    return HeapStatistics(new v8::HeapStatistics());
  }
  VALUE HeapStatistics::total_heap_size(VALUE self) {
    return SIZET2NUM(HeapStatistics(self)->total_heap_size());
  }
  VALUE HeapStatistics::total_heap_size_executable(VALUE self) {
    return SIZET2NUM(HeapStatistics(self)->total_heap_size_executable());
  }
  VALUE HeapStatistics::total_physical_size(VALUE self) {
    return SIZET2NUM(HeapStatistics(self)->total_physical_size());
  }
  VALUE HeapStatistics::used_heap_size(VALUE self) {
    return SIZET2NUM(HeapStatistics(self)->used_heap_size());
  }
  VALUE HeapStatistics::heap_size_limit(VALUE self) {
    return SIZET2NUM(HeapStatistics(self)->heap_size_limit());
  }
  template <> void Pointer<v8::HeapStatistics>::unwrap(VALUE value) {
    Data_Get_Struct(value, class v8::HeapStatistics, pointer);
  }
}
