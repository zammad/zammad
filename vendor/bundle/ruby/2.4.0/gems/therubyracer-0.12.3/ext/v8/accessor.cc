#include "rr.h"

namespace rr {

  VALUE Accessor::Info::Class;

  void Accessor::Init() {
    ClassBuilder("AccessorInfo").
      defineMethod("This", &Info::This).
      defineMethod("Holder", &Info::Holder).
      defineMethod("Data", &Info::Data).
      store(&Info::Class);
  }

  Accessor::Accessor(VALUE getter, VALUE setter, VALUE data_) : get(getter), set(setter), query(Qnil), deleter(Qnil), enumerator(Qnil), data(data_) {}

  Accessor::Accessor(VALUE get, VALUE set, VALUE query, VALUE deleter, VALUE enumerator, VALUE data) {
    this->get = get;
    this->set = set;
    this->query = query;
    this->deleter = deleter;
    this->enumerator = enumerator;
    this->data = data;
  }

  Accessor::Accessor(v8::Handle<v8::Value> value) {
    v8::Local<v8::Object> wrapper = value->ToObject();
    this->get = unwrap(wrapper, 0);
    this->set = unwrap(wrapper, 1);
    this->query = unwrap(wrapper, 2);
    this->deleter = unwrap(wrapper, 3);
    this->enumerator = unwrap(wrapper, 4);
    v8::Handle<v8::Value> data = wrapper->Get(5);
    if (!data.IsEmpty() && !data->IsNull() && !data->IsUndefined()) {
      this->data = Value(data);
    }
  }

  Accessor::operator v8::Handle<v8::Value>() {
    v8::Local<v8::Object> wrapper = v8::Object::New();
    wrap(wrapper, 0, this->get);
    wrap(wrapper, 1, this->set);
    wrap(wrapper, 2, this->query);
    wrap(wrapper, 3, this->deleter);
    wrap(wrapper, 4, this->enumerator);
    if (RTEST(this->data)) {
      wrapper->Set(5, Value(this->data));
    }
    return wrapper;
  }

  void Accessor::wrap(v8::Handle<v8::Object> wrapper, int index, VALUE value) {
    if (RTEST(value)) {
      wrapper->Set(index, External::wrap(value));
    }
  }

  VALUE Accessor::unwrap(v8::Handle<v8::Object> wrapper, int index) {
    v8::Handle<v8::Value> value = wrapper->Get(index);
    if (value.IsEmpty() || !value->IsExternal()) {
      return Qnil;
    } else {
      v8::Handle<v8::External> external(v8::External::Cast(*value));
      return External::unwrap(external);
    }
  }


  VALUE Accessor::Info::This(VALUE self) {
    return Object(Info(self)->This());
  }

  VALUE Accessor::Info::Holder(VALUE self) {
    return Object(Info(self)->Holder());
  }

  VALUE Accessor::Info::Data(VALUE self) {
    return Accessor(Info(self)->Data()).data;
  }

  v8::Handle<v8::Value> Accessor::AccessorGetter(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
    return Info(info).get(property);
  }

  void Accessor::AccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
    Info(info).set(property, value);
  }
  v8::Handle<v8::Value> Accessor::NamedPropertyGetter(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
    return Info(info).get(property);
  }
  v8::Handle<v8::Value> Accessor::NamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
    return Info(info).set(property, value);
  }
  v8::Handle<v8::Integer> Accessor::NamedPropertyQuery(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
    return Info(info).query(property);
  }
  v8::Handle<v8::Boolean> Accessor::NamedPropertyDeleter(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
    return Info(info).remove(property);
  }
  v8::Handle<v8::Array> Accessor::NamedPropertyEnumerator(const v8::AccessorInfo& info) {
    return Info(info).enumerateNames();
  }

  v8::Handle<v8::Value> Accessor::IndexedPropertyGetter(uint32_t index, const v8::AccessorInfo& info) {
    return Info(info).get(index);
  }
  v8::Handle<v8::Value> Accessor::IndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
    return Info(info).set(index, value);
  }
  v8::Handle<v8::Integer> Accessor::IndexedPropertyQuery(uint32_t index, const v8::AccessorInfo& info) {
    return Info(info).query(index);
  }
  v8::Handle<v8::Boolean> Accessor::IndexedPropertyDeleter(uint32_t index, const v8::AccessorInfo& info) {
    return Info(info).remove(index);
  }
  v8::Handle<v8::Array> Accessor::IndexedPropertyEnumerator(const v8::AccessorInfo& info) {
    return Info(info).enumerateIndices();
  }

  Accessor::Info::Info(const v8::AccessorInfo& info) {
    this->info = &info;
  }

  Accessor::Info::Info(VALUE value) {
    Data_Get_Struct(value, class v8::AccessorInfo, info);
  }

  v8::Handle<v8::Value> Accessor::Info::get(v8::Local<v8::String> property) {
    Accessor accessor(info->Data());
    return Value(rb_funcall(accessor.get, rb_intern("call"), 2, (VALUE)String(property), (VALUE)*this));
  }

  v8::Handle<v8::Value> Accessor::Info::set(v8::Local<v8::String> property, v8::Local<v8::Value> value) {
    Accessor accessor(info->Data());
    return Value(rb_funcall(accessor.set, rb_intern("call"), 3, (VALUE)String(property), (VALUE)Value(value), (VALUE)*this));
  }

  v8::Handle<v8::Integer> Accessor::Info::query(v8::Local<v8::String> property) {
    Accessor accessor(info->Data());
    return v8::Integer::New(NUM2INT(rb_funcall(accessor.query, rb_intern("call"), 2, (VALUE)String(property), (VALUE)*this)));
  }

  v8::Handle<v8::Boolean> Accessor::Info::remove(v8::Local<v8::String> property) {
    Accessor accessor(info->Data());
    return v8::Boolean::New(Bool(rb_funcall(accessor.deleter, rb_intern("call"), 2, (VALUE)String(property), (VALUE)*this)));
  }

  v8::Handle<v8::Array> Accessor::Info::enumerateNames() {
    Accessor accessor(info->Data());
    return Array(rb_funcall(accessor.enumerator, rb_intern("call"), 1, (VALUE)*this));
  }

  v8::Handle<v8::Value> Accessor::Info::get(uint32_t index) {
    Accessor accessor(info->Data());
    return Value(rb_funcall(accessor.get, rb_intern("call"), 2, UINT2NUM(index), (VALUE)*this));
  }

  v8::Handle<v8::Value> Accessor::Info::set(uint32_t index, v8::Local<v8::Value> value) {
    Accessor accessor(info->Data());
    return Value(rb_funcall(accessor.set, rb_intern("call"), 3, UINT2NUM(index), (VALUE)Value(value), (VALUE)*this));
  }

  v8::Handle<v8::Integer> Accessor::Info::query(uint32_t index) {
    Accessor accessor(info->Data());
    return v8::Integer::New(NUM2INT(rb_funcall(accessor.query, rb_intern("call"), 2, UINT2NUM(index), (VALUE)*this)));
  }

  v8::Handle<v8::Boolean> Accessor::Info::remove(uint32_t index) {
    Accessor accessor(info->Data());
    return v8::Boolean::New(Bool(rb_funcall(accessor.deleter, rb_intern("call"), 2, UINT2NUM(index), (VALUE)*this)));
  }

  v8::Handle<v8::Array> Accessor::Info::enumerateIndices() {
    Accessor accessor(info->Data());
    return Array(rb_funcall(accessor.enumerator, rb_intern("call"), 1, (VALUE)*this));
  }

  Accessor::Info::operator VALUE() {
    return Data_Wrap_Struct(Class, 0, 0, (void*)this->info);
  }
}