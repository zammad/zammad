#include "rr.h"

namespace rr {

  VALUE Invocation::Arguments::Class;

  void Invocation::Init() {
    Arguments::Init();
  }

  void Invocation::Arguments::Init() {
    ClassBuilder("Arguments").
      defineMethod("Length", &Length).
      defineMethod("[]", &Get).
      defineMethod("Callee", &Callee).
      defineMethod("This", &This).
      defineMethod("Holder", &Holder).
      defineMethod("IsConstructCall", &IsConstructCall).
      defineMethod("Data", &Data).
    store(&Invocation::Arguments::Class);
  }

  Invocation::Invocation(VALUE code, VALUE data) {
    this->code = code;
    this->data = data;
  }
  Invocation::Invocation(v8::Handle<v8::Value> value) {
    v8::Local<v8::Object> wrapper = value->ToObject();
    this->code = External::unwrap((v8::Handle<v8::External>)v8::External::Cast(*wrapper->Get(0)));
    this->data = Value(wrapper->Get(1));
  }
  Invocation::operator v8::InvocationCallback() {
    return &Callback;
  }
  Invocation::operator v8::Handle<v8::Value>() {
    v8::Local<v8::Object> wrapper = v8::Object::New();
    wrapper->Set(0, External::wrap(this->code));
    wrapper->Set(1, Value(this->data));
    return wrapper;
  }

  v8::Handle<v8::Value> Invocation::Callback(const v8::Arguments& args) {
    return Arguments(args).Call();
  }

  Invocation::Arguments::Arguments(const v8::Arguments& args) {
    this->args = &args;
  }

  Invocation::Arguments::Arguments(VALUE value) {
    Data_Get_Struct(value, class v8::Arguments, args);
  }

  v8::Handle<v8::Value> Invocation::Arguments::Call() {
    Invocation invocation(args->Data());
    return Value(rb_funcall(invocation.code, rb_intern("call"), 1, Data_Wrap_Struct(Class, 0, 0, (void*)this->args)));
  }

  VALUE Invocation::Arguments::Length(VALUE self) {
    return INT2FIX(Arguments(self)->Length());
  }

  VALUE Invocation::Arguments::Get(VALUE self, VALUE index) {
    return Value((*Arguments(self))[NUM2INT(index)]);
  }

  VALUE Invocation::Arguments::Callee(VALUE self) {
    return Function(Arguments(self)->Callee());
  }

  VALUE Invocation::Arguments::This(VALUE self) {
    return Object(Arguments(self)->This());
  }

  VALUE Invocation::Arguments::Holder(VALUE self) {
    return Object(Arguments(self)->Holder());
  }

  VALUE Invocation::Arguments::IsConstructCall(VALUE self) {
    return Bool(Arguments(self)->IsConstructCall());
  }

  VALUE Invocation::Arguments::Data(VALUE self) {
    return Invocation(Arguments(self)->Data()).data;
  }
}