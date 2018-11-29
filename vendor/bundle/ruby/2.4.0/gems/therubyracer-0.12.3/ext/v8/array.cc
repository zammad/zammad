#include "rr.h"

namespace rr {

void Array::Init() {
  ClassBuilder("Array", Object::Class).
    defineSingletonMethod("New", &New).
    defineMethod("Length", &Length).
    defineMethod("CloneElementAt", &CloneElementAt).
    store(&Class);
}

VALUE Array::New(int argc, VALUE argv[], VALUE self) {
  VALUE length; rb_scan_args(argc, argv, "01", &length);
  return Array(v8::Array::New(RTEST(length) ? NUM2INT(length) : 0));
}

VALUE Array::Length(VALUE self) {
  return UInt32(Array(self)->Length());
}

VALUE Array::CloneElementAt(VALUE self, VALUE index) {
  return Object(Array(self)->CloneElementAt(UInt32(index)));
}

}