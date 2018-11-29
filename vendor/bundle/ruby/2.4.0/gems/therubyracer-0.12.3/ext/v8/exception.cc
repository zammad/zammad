#include "rr.h"

namespace rr {
  void Exception::Init() {
    ModuleBuilder("V8::C").
      defineSingletonMethod("ThrowException", &ThrowException);
    ClassBuilder("Exception").
      defineSingletonMethod("RangeError", &RangeError).
      defineSingletonMethod("ReferenceError", &ReferenceError).
      defineSingletonMethod("SyntaxError", &SyntaxError).
      defineSingletonMethod("TypeError", &TypeError).
      defineSingletonMethod("Error", &Error);
  }

  VALUE Exception::ThrowException(VALUE self, VALUE exception) {
    return Value(v8::ThrowException(Value(exception)));
  }

  VALUE Exception::RangeError(VALUE self, VALUE message) {
    return Value(v8::Exception::RangeError(String(message)));
  }

  VALUE Exception::ReferenceError(VALUE self, VALUE message) {
    return Value(v8::Exception::ReferenceError(String(message)));
  }

  VALUE Exception::SyntaxError(VALUE self, VALUE message) {
    return Value(v8::Exception::SyntaxError(String(message)));
  }

  VALUE Exception::TypeError(VALUE self, VALUE message) {
    return Value(v8::Exception::TypeError(String(message)));
  }

  VALUE Exception::Error(VALUE self, VALUE message) {
    return Value(v8::Exception::Error(String(message)));
  }
}