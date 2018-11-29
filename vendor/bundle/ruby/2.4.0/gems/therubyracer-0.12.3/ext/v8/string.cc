#include "rr.h"

namespace rr {

void String::Init() {
  ClassBuilder("String", Primitive::Class).
    defineSingletonMethod("New", &New).
    defineSingletonMethod("NewSymbol", &NewSymbol).
    defineSingletonMethod("Concat", &Concat).
    defineMethod("Utf8Value", &Utf8Value).
    store(&Class);
}

VALUE String::New(VALUE StringClass, VALUE string) {
  return String(v8::String::New(RSTRING_PTR(string), (int)RSTRING_LEN(string)));
}

VALUE String::NewSymbol(VALUE self, VALUE string) {
  return String(v8::String::NewSymbol(RSTRING_PTR(string), (int)RSTRING_LEN(string)));
}

VALUE String::Utf8Value(VALUE self) {
  String str(self);
  #ifdef HAVE_RUBY_ENCODING_H
  return rb_enc_str_new(*v8::String::Utf8Value(*str), str->Utf8Length(), rb_enc_find("utf-8"));
  #else
  return rb_str_new(*v8::String::Utf8Value(*str), str->Utf8Length());
  #endif
}

VALUE String::Concat(VALUE self, VALUE left, VALUE right) {
  return String(v8::String::Concat(String(left), String(right)));
}

String::operator v8::Handle<v8::String>() const {
  switch (TYPE(value)) {
  case T_STRING:
    return v8::String::New(RSTRING_PTR(value), (int)RSTRING_LEN(value));
  case T_DATA:
    return Ref<v8::String>::operator v8::Handle<v8::String>();
  default:
    VALUE string = rb_funcall(value, rb_intern("to_s"), 0);
    return v8::String::New(RSTRING_PTR(string), (int)RSTRING_LEN(string));
  }
}

} //namespace rr