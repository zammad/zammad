#include "rr.h"

namespace rr {
  void Template::Init() {
    ClassBuilder("Template").
      defineMethod("Set", &Set);
    ObjectTemplate::Init();
    FunctionTemplate::Init();
  }

  VALUE Template::Set(int argc, VALUE argv[], VALUE self) {
    VALUE name; VALUE value; VALUE attributes;
    rb_scan_args(argc, argv, "21", &name, &value, &attributes);
    Void(Template(self)->Set(*String(name), *Value(value), PropertyAttribute(attributes)));
  }

  void ObjectTemplate::Init() {
    ClassBuilder("ObjectTemplate", "Template").
      defineSingletonMethod("New", &New).
      defineMethod("NewInstance", &NewInstance).
      defineMethod("SetAccessor", &SetAccessor).
      defineMethod("SetNamedPropertyHandler", &SetNamedPropertyHandler).
      defineMethod("SetIndexedPropertyHandler", &SetIndexedPropertyHandler).
      defineMethod("SetCallAsFunctionHandler", &SetCallAsFunctionHandler).
      defineMethod("MarkAsUndetectable", &MarkAsUndetectable).
      defineMethod("SetAccessCheckCallbacks", &SetAccessCheckCallbacks).
      defineMethod("InternalFieldCount", &InternalFieldCount).
      defineMethod("SetInternalFieldCount", &SetInternalFieldCount).
      store(&Class);
  }

  VALUE ObjectTemplate::New(VALUE self) {
    return ObjectTemplate(v8::ObjectTemplate::New());
  }

  VALUE ObjectTemplate::NewInstance(VALUE self) {
    return Object(ObjectTemplate(self)->NewInstance());
  }

  VALUE ObjectTemplate::SetAccessor(int argc, VALUE argv[], VALUE self) {
    VALUE name; VALUE get; VALUE set; VALUE data; VALUE settings; VALUE attribs;
    rb_scan_args(argc, argv, "24", &name, &get, &set, &data, &settings, &attribs);
    Accessor accessor(get, set, data);
    ObjectTemplate(self)->SetAccessor(
      String(name),
      accessor.accessorGetter(),
      accessor.accessorSetter(),
      accessor,
      AccessControl(settings),
      PropertyAttribute(attribs)
    );
    Void();
  }

  VALUE ObjectTemplate::SetNamedPropertyHandler(int argc, VALUE argv[], VALUE self) {
    VALUE get; VALUE set; VALUE query; VALUE deleter; VALUE enumerator; VALUE data;
    rb_scan_args(argc, argv, "15", &get, &set, &query, &deleter, &enumerator, &data);
    Accessor accessor(get,set,query,deleter,enumerator,data);
    ObjectTemplate(self)->SetNamedPropertyHandler(
      accessor.namedPropertyGetter(),
      accessor.namedPropertySetter(),
      accessor.namedPropertyQuery(),
      accessor.namedPropertyDeleter(),
      accessor.namedPropertyEnumerator(),
      accessor
    );
    Void();
  }

   VALUE ObjectTemplate::SetIndexedPropertyHandler(int argc, VALUE argv[], VALUE self) {
     VALUE get; VALUE set; VALUE query; VALUE deleter; VALUE enumerator; VALUE data;
     rb_scan_args(argc, argv, "15", &get, &set, &query, &deleter, &enumerator, &data);
     Accessor accessor(get,set,query,deleter,enumerator,data);
     ObjectTemplate(self)->SetIndexedPropertyHandler(
       accessor.indexedPropertyGetter(),
       accessor.indexedPropertySetter(),
       accessor.indexedPropertyQuery(),
       accessor.indexedPropertyDeleter(),
       accessor.indexedPropertyEnumerator(),
       accessor
     );
     Void();
   }

   VALUE ObjectTemplate::SetCallAsFunctionHandler(int argc, VALUE argv[], VALUE self) {
     VALUE callback; VALUE data;
     rb_scan_args(argc, argv, "11", &callback, &data);
     Invocation invocation(callback, data);
     Void(ObjectTemplate(self)->SetCallAsFunctionHandler(invocation, invocation));
   }

   VALUE ObjectTemplate::MarkAsUndetectable(VALUE self) {
     Void(ObjectTemplate(self)->MarkAsUndetectable());
   }


   VALUE ObjectTemplate::SetAccessCheckCallbacks(int argc, VALUE argv[], VALUE self) {
     VALUE named_handler; VALUE indexed_handler; VALUE data; VALUE turned_on_by_default;
     rb_scan_args(argc, argv, "22", &named_handler, &indexed_handler, &data, &turned_on_by_default);
     return not_implemented("ObjectTemplate::SetAccessCheckCallbacks");
   }

   VALUE ObjectTemplate::InternalFieldCount(VALUE self) {
     return INT2FIX(ObjectTemplate(self)->InternalFieldCount());
   }

   VALUE ObjectTemplate::SetInternalFieldCount(VALUE self, VALUE count) {
     Void(ObjectTemplate(self)->SetInternalFieldCount(NUM2INT(count)));
   }

  void FunctionTemplate::Init() {
    ClassBuilder("FunctionTemplate", "Template").
      defineSingletonMethod("New", &New).
      defineMethod("GetFunction", &GetFunction).
      defineMethod("SetCallHandler", &SetCallHandler).
      defineMethod("InstanceTemplate", &InstanceTemplate).
      defineMethod("Inherit", &Inherit).
      defineMethod("PrototypeTemplate", &PrototypeTemplate).
      defineMethod("SetClassName", &SetClassName).
      defineMethod("SetHiddenPrototype", &SetHiddenPrototype).
      defineMethod("ReadOnlyPrototype", &ReadOnlyPrototype).
      defineMethod("HasInstance", &HasInstance).
      store(&Class);
  }

  VALUE FunctionTemplate::New(int argc, VALUE argv[], VALUE self) {
    VALUE code; VALUE data; VALUE signature;
    rb_scan_args(argc, argv, "03", &code, &data, &signature);
    if (RTEST(code)) {
      Invocation invocation(code, data);
      return FunctionTemplate(v8::FunctionTemplate::New(invocation, invocation, Signature(signature)));
    } else {
      return FunctionTemplate(v8::FunctionTemplate::New());
    }
  }

  VALUE FunctionTemplate::GetFunction(VALUE self) {
    return Function(FunctionTemplate(self)->GetFunction());
  }

  VALUE FunctionTemplate::SetCallHandler(int argc, VALUE argv[], VALUE self) {
    VALUE code; VALUE data;
    rb_scan_args(argc, argv, "11", &code, &data);
    Invocation invocation(code, data);
    Void(FunctionTemplate(self)->SetCallHandler(invocation, invocation));
  }

  VALUE FunctionTemplate::InstanceTemplate(VALUE self) {
    return ObjectTemplate(FunctionTemplate(self)->InstanceTemplate());
  }

  VALUE FunctionTemplate::Inherit(VALUE self, VALUE parent) {
    Void(FunctionTemplate(self)->Inherit(FunctionTemplate(parent)));
  }

  VALUE FunctionTemplate::PrototypeTemplate(VALUE self) {
    return ObjectTemplate(FunctionTemplate(self)->PrototypeTemplate());
  }

  VALUE FunctionTemplate::SetClassName(VALUE self, VALUE name) {
    Void(FunctionTemplate(self)->SetClassName(String(name)));
  }

  VALUE FunctionTemplate::SetHiddenPrototype(VALUE self, VALUE value) {
    Void(FunctionTemplate(self)->SetHiddenPrototype(Bool(value)));
  }

  VALUE FunctionTemplate::ReadOnlyPrototype(VALUE self) {
    Void(FunctionTemplate(self)->ReadOnlyPrototype());
  }

  VALUE FunctionTemplate::HasInstance(VALUE self, VALUE object) {
    return Bool(FunctionTemplate(self)->HasInstance(Value(object)));
  }
}