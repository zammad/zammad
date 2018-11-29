#include "rr.h"

namespace rr {
  void Primitive::Init() {
    ClassBuilder("Primitive", Value::Class).
      store(&Class);
  }
}