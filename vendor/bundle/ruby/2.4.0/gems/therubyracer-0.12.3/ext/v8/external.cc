#include "rr.h"

namespace rr {

void External::Init() {
  ClassBuilder("External", "Value").
    defineSingletonMethod("New", &New).
    defineMethod("Value", &Value).
    store(&Class);
}
VALUE External::New(VALUE self, VALUE data) {
  return External(wrap(data));
}

v8::Handle<v8::External> External::wrap(VALUE data) {
  Data* holder = new Data(data);
  v8::Local<v8::External> ext = v8::External::New(holder);
  v8::Persistent<v8::External>::New(ext).MakeWeak(holder, &release);
  return ext;
}

VALUE External::unwrap(v8::Handle<v8::External> external) {
  Data* data = (Data*)(external->Value());
  return data->value;
}

VALUE External::Value(VALUE self) {
  return unwrap(External(self));
}

void External::release(v8::Persistent<v8::Value> handle, void* parameter) {
  handle.Dispose();
  Data* data = (Data*)parameter;
  delete data;
}
External::Data::Data(VALUE data) {
  this->value = data;
  rb_gc_register_address(&value);
}
External::Data::~Data() {
  rb_gc_unregister_address(&value);
}
}