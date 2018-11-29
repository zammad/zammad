#include "rr.h"

namespace rr {
  VALUE Constants::_Undefined;
  VALUE Constants::_Null;
  VALUE Constants::_True;
  VALUE Constants::_False;
  void Constants::Init() {
    ModuleBuilder("V8::C").
      defineSingletonMethod("Undefined", &Undefined).
      defineSingletonMethod("Null", &Null).
      defineSingletonMethod("True", &True).
      defineSingletonMethod("False", &False);

    _Undefined = _Null = _True = _False = Qnil;
    rb_gc_register_address(&_Undefined);
    rb_gc_register_address(&_Null);
    rb_gc_register_address(&_True);
    rb_gc_register_address(&_False);
  }

  VALUE Constants::Undefined(VALUE self) {
    return cached<Primitive, v8::Primitive>(&_Undefined, v8::Undefined());
  }
  VALUE Constants::Null(VALUE self) {
    return cached<Primitive, v8::Primitive>(&_Null, v8::Null());
  }
  VALUE Constants::True(VALUE self) {
    return cached<Bool, v8::Boolean>(&_True, v8::True());
  }
  VALUE Constants::False(VALUE self) {
    return cached<Bool, v8::Boolean>(&_False, v8::False());
  }
}