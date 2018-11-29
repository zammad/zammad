#include "rr.h"

namespace rr {

  void Date::Init() {
    ClassBuilder("Date", Value::Class).
      defineSingletonMethod("New", &New).
      defineMethod("NumberValue", &NumberValue).
      store(&Class);
  }

  VALUE Date::New(VALUE self, VALUE time) {
    return Value(v8::Date::New(NUM2DBL(time)));
  }
  VALUE Date::NumberValue(VALUE self) {
    return rb_float_new(Date(self)->NumberValue());
  }
}