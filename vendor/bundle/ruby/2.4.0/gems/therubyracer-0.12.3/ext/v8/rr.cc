#include "rr.h"

namespace rr {
  VALUE defineClass(const char *name, VALUE superclass = rb_cObject) {
    VALUE V8 = rb_define_module("V8");
    VALUE V8_C = rb_define_module_under(V8, "C");
    VALUE klass = rb_define_class_under(V8_C, name, superclass);
    rb_funcall(klass, rb_intern("private_class_method"), 1, rb_str_new2("new"));
    return klass;
  }

  VALUE defineModule(const char *name) {
    VALUE V8 = rb_define_module("V8");
    VALUE V8_C = rb_define_module_under(V8, "C");
    return rb_define_module_under(V8_C, name);
  }

  VALUE not_implemented(const char* message) {
    Void(rb_raise(rb_eStandardError, "not yet implemented %s", message));
  }

  ClassBuilder::ClassBuilder(const char* name, VALUE superclass) {
    this->value = defineClass(name, superclass);
  }

  ClassBuilder::ClassBuilder(const char* name, const char* supername) {
    VALUE superclass = defineClass(supername);
    this->value = defineClass(name, superclass);
  }
  ClassBuilder& ClassBuilder::defineConst(const char* name, VALUE value) {
    rb_define_const(this->value, name, value);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineMethod(const char* name, VALUE (*impl)(int, VALUE*, VALUE)) {
    rb_define_method(this->value, name, (VALUE (*)(...))impl, -1);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineMethod(const char* name, VALUE (*impl)(VALUE)) {
    rb_define_method(this->value, name, (VALUE (*)(...))impl, 0);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE)) {
    rb_define_method(this->value, name, (VALUE (*)(...))impl, 1);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE)) {
    rb_define_method(this->value, name, (VALUE (*)(...))impl, 2);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE, VALUE)) {
    rb_define_method(this->value, name, (VALUE (*)(...))impl, 3);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineSingletonMethod(const char* name, VALUE (*impl)(int, VALUE*, VALUE)) {
    rb_define_singleton_method(this->value, name, (VALUE (*)(...))impl, -1);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineSingletonMethod(const char* name, VALUE (*impl)(VALUE)) {
    rb_define_singleton_method(this->value, name, (VALUE (*)(...))impl, 0);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE)) {
    rb_define_singleton_method(this->value, name, (VALUE (*)(...))impl, 1);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE)) {
    rb_define_singleton_method(this->value, name, (VALUE (*)(...))impl, 2);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE, VALUE)) {
    rb_define_singleton_method(this->value, name, (VALUE (*)(...))impl, 3);
    return *this;
  }
  ClassBuilder& ClassBuilder::defineEnumConst(const char* name, int value) {
    rb_define_const(this->value, name, INT2FIX(value));
    return *this;
  }
  ClassBuilder& ClassBuilder::store(VALUE* storage) {
    rb_gc_register_address(storage);
    *storage = this->value;
    return *this;
  }
}