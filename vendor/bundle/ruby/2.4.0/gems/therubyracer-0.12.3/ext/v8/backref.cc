#include "rr.h"

namespace rr {

  VALUE Backref::Storage;
  ID Backref::_new;
  ID Backref::object;

  void Backref::Init() {
    Storage = rb_eval_string("V8::Weak::Ref");
    rb_gc_register_address(&Storage);
    _new = rb_intern("new");
    object = rb_intern("object");
  }

  Backref::Backref(VALUE initial) {
    set(initial);
    rb_gc_register_address(&storage);
  }

  Backref::~Backref() {
    rb_gc_unregister_address(&storage);
  }

  VALUE Backref::set(VALUE data) {
    this->storage = rb_funcall(Storage, _new, 1, data);
    return data;
  }

  VALUE Backref::get() {
    return rb_funcall(storage, object, 0);
  }

  v8::Handle<v8::Value> Backref::toExternal() {
    v8::Local<v8::Value> wrapper = v8::External::New(this);
    v8::Persistent<v8::Value>::New(wrapper).MakeWeak(this, &release);
    return wrapper;
  }

  void Backref::release(v8::Persistent<v8::Value> handle, void* data) {
    handle.Dispose();
    Backref* backref = (Backref*)data;
    delete backref;
  }
}
