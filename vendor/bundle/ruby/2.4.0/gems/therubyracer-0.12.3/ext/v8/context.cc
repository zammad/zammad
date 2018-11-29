#include "rr.h"

namespace rr {

void Context::Init() {
  ClassBuilder("Context").
    defineSingletonMethod("New", &New).
    defineSingletonMethod("GetCurrent", &GetCurrent).
    defineSingletonMethod("GetEntered", &GetEntered).
    defineSingletonMethod("GetCalling", &GetCalling).
    defineSingletonMethod("InContext", &InContext).
    defineMethod("Dispose", &Dispose).
    defineMethod("Global", &Global).
    defineMethod("DetachGlobal", &Global).
    defineMethod("ReattachGlobal", &ReattachGlobal).
    defineMethod("SetSecurityToken", &SetSecurityToken).
    defineMethod("UseDefaultSecurityToken", &UseDefaultSecurityToken).
    defineMethod("GetSecurityToken", &GetSecurityToken).
    defineMethod("HasOutOfMemoryException", &HasOutOfMemoryException).
    defineMethod("SetEmbedderData", &SetEmbedderData).
    defineMethod("GetEmbedderData", &GetEmbedderData).
    defineMethod("AllowCodeGenerationFromStrings", &AllowCodeGenerationFromStrings).
    defineMethod("IsCodeGenerationFromStringsAllowed", &IsCodeGenerationFromStringsAllowed).
    defineMethod("Enter", &Enter).
    defineMethod("Exit", &Exit).
    store(&Class);
  ClassBuilder("ExtensionConfiguration").
    defineSingletonMethod("new", &ExtensionConfiguration::initialize).
    store(&ExtensionConfiguration::Class);
}

VALUE Context::Dispose(VALUE self) {
  Void(Context(self).dispose())
}

VALUE Context::Global(VALUE self) {
  return Object(Context(self)->Global());
}

VALUE Context::DetachGlobal(VALUE self) {
  Void(Context(self)->DetachGlobal());
}

VALUE Context::ReattachGlobal(VALUE self, VALUE global) {
  Void(Context(self)->ReattachGlobal(Object(global)));
}

VALUE Context::GetEntered(VALUE self) {
  return Context(v8::Context::GetEntered());
}

VALUE Context::GetCurrent(VALUE self) {
  return Context(v8::Context::GetCurrent());
}

VALUE Context::GetCalling(VALUE self) {
  return Context(v8::Context::GetCalling());
}

VALUE Context::SetSecurityToken(VALUE self, VALUE token) {
  Void(Context(self)->SetSecurityToken(Value(token)));
}

VALUE Context::UseDefaultSecurityToken(VALUE self) {
  Void(Context(self)->UseDefaultSecurityToken());
}

VALUE Context::GetSecurityToken(VALUE self) {
  return Value(Context(self)->GetSecurityToken());
}

VALUE Context::HasOutOfMemoryException(VALUE self) {
  return Bool(Context(self)->HasOutOfMemoryException());
}

VALUE Context::InContext(VALUE self) {
  return Bool(v8::Context::InContext());
}

VALUE Context::SetEmbedderData(VALUE self, VALUE index, VALUE data) {
  Void(Context(self)->SetEmbedderData(NUM2INT(index), Value(data)));
}

VALUE Context::GetEmbedderData(VALUE self, VALUE index) {
  Void(Context(self)->GetEmbedderData(NUM2INT(index)));
}

VALUE Context::AllowCodeGenerationFromStrings(VALUE self, VALUE allow) {
  Void(Context(self)->AllowCodeGenerationFromStrings(RTEST(allow)));
}

VALUE Context::IsCodeGenerationFromStringsAllowed(VALUE self) {
  return Bool(Context(self)->IsCodeGenerationFromStringsAllowed());
}

VALUE ExtensionConfiguration::initialize(VALUE self, VALUE names) {
  int length = RARRAY_LENINT(names);
  const char* array[length];
  for (int i = 0; i < length; i++) {
    array[i] = RSTRING_PTR(rb_ary_entry(names, i));
  }
  return ExtensionConfiguration(new v8::ExtensionConfiguration(length, array));
}

VALUE Context::New(int argc, VALUE argv[], VALUE self) {
  VALUE extension_configuration; VALUE global_template; VALUE global_object;
  rb_scan_args(argc, argv, "03", &extension_configuration, &global_template, &global_object);
  v8::Persistent<v8::Context> context(v8::Context::New(
    ExtensionConfiguration(extension_configuration),
    *ObjectTemplate(global_template),
    *Object(global_object)
  ));
  Context reference(context);
  context.Dispose();
  return reference;
}

VALUE Context::Enter(VALUE self) {
  Void(Context(self)->Enter());
}

VALUE Context::Exit(VALUE self) {
  Void(Context(self)->Exit());
}

template <> void Pointer<v8::ExtensionConfiguration>::unwrap(VALUE value) {
  Data_Get_Struct(value, class v8::ExtensionConfiguration, pointer);
}

}
