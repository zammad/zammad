#include "rr.h"

namespace rr {

void Object::Init() {
  ClassBuilder("Object", Value::Class).
    defineSingletonMethod("New", &New).
    defineMethod("Set", &Set).
    defineMethod("ForceSet", &ForceSet).
    defineMethod("Get", &Get).
    defineMethod("GetPropertyAttributes", &GetPropertyAttributes).
    defineMethod("Has", &Has).
    defineMethod("Delete", &Delete).
    defineMethod("ForceDelete", &ForceDelete).
    defineMethod("SetAccessor", &SetAccessor).
    defineMethod("GetPropertyNames", &GetPropertyNames).
    defineMethod("GetOwnPropertyNames", &GetOwnPropertyNames).
    defineMethod("GetPrototype", &GetPrototype).
    defineMethod("SetPrototype", &SetPrototype).
    defineMethod("FindInstanceInPrototypeChain", &FindInstanceInPrototypeChain).
    defineMethod("ObjectProtoToString", &ObjectProtoToString).
    defineMethod("GetConstructorName", &GetConstructorName).
    defineMethod("InternalFieldCount", &InternalFieldCount).
    defineMethod("GetInternalField", &GetInternalField).
    defineMethod("SetInternalField", &SetInternalField).
    defineMethod("HasOwnProperty", &HasOwnProperty).
    defineMethod("HasRealNamedProperty", &HasRealNamedProperty).
    defineMethod("HasRealIndexedProperty", &HasRealIndexedProperty).
    defineMethod("HasRealNamedCallbackProperty", &HasRealNamedCallbackProperty).
    defineMethod("GetRealNamedPropertyInPrototypeChain", &GetRealNamedPropertyInPrototypeChain).
    defineMethod("GetRealNamedProperty", &GetRealNamedProperty).
    defineMethod("HasNamedLookupInterceptor", &HasNamedLookupInterceptor).
    defineMethod("HasIndexedLookupInterceptor", &HasIndexedLookupInterceptor).
    defineMethod("TurnOnAccessCheck", &TurnOnAccessCheck).
    defineMethod("GetIdentityHash", &GetIdentityHash).
    defineMethod("SetHiddenValue", &SetHiddenValue).
    defineMethod("GetHiddenValue", &GetHiddenValue).
    defineMethod("DeleteHiddenValue", &DeleteHiddenValue).
    defineMethod("IsDirty", &IsDirty).
    defineMethod("Clone", &Clone).
    defineMethod("CreationContext", &CreationContext).
    defineMethod("SetIndexedPropertiesToPixelData", &SetIndexedPropertiesToPixelData).
    defineMethod("GetIndexedPropertiesPixelData", &GetIndexedPropertiesPixelData).
    defineMethod("HasIndexedPropertiesToPixelData", &HasIndexedPropertiesInPixelData).
    defineMethod("GetIndexedPropertiesPixelDataLength", &GetIndexedPropertiesPixelDataLength).
    defineMethod("SetIndexedPropertiesToExternalArrayData", &SetIndexedPropertiesToExternalArrayData).
    defineMethod("HasIndexedPropertiesInExternalArrayData", &HasIndexedPropertiesInExternalArrayData).
    defineMethod("GetIndexedPropertiesExternalArrayData", &GetIndexedPropertiesExternalArrayData).
    defineMethod("GetIndexedPropertiesExternalArrayDataType", &GetIndexedPropertiesExternalArrayDataType).
    defineMethod("GetIndexedPropertiesExternalArrayDataLength", &GetIndexedPropertiesExternalArrayDataLength).
    defineMethod("IsCallable", &IsCallable).
    defineMethod("CallAsFunction", &CallAsFunction).
    defineMethod("CallAsConstructor", &CallAsConstructor).
    store(&Class);
  ClassBuilder("PropertyAttribute").
    defineEnumConst("None", v8::None).
    defineEnumConst("ReadOnly", v8::ReadOnly).
    defineEnumConst("DontEnum", v8::DontEnum).
    defineEnumConst("DontDelete", v8::DontDelete);
  ClassBuilder("AccessControl").
    defineEnumConst("DEFAULT", v8::DEFAULT).
    defineEnumConst("ALL_CAN_READ", v8::ALL_CAN_READ).
    defineEnumConst("ALL_CAN_WRITE", v8::ALL_CAN_WRITE).
    defineEnumConst("PROHIBITS_OVERWRITING", v8::PROHIBITS_OVERWRITING);
}


VALUE Object::New(VALUE self) {
  return Object(v8::Object::New());
}

//TODO: Allow setting of property attributes
VALUE Object::Set(VALUE self, VALUE key, VALUE value) {
  if (rb_obj_is_kind_of(key, rb_cNumeric)) {
    return Bool(Object(self)->Set(UInt32(key), Value(value)));
  } else {
    return Bool(Object(self)->Set(*Value(key), Value(value)));
  }
}

VALUE Object::ForceSet(VALUE self, VALUE key, VALUE value) {
  return Bool(Object(self)->ForceSet(Value(key), Value(value)));
}

VALUE Object::Get(VALUE self, VALUE key) {
  if (rb_obj_is_kind_of(key, rb_cNumeric)) {
    return Value(Object(self)->Get(UInt32(key)));
  } else {
    return Value(Object(self)->Get(*Value(key)));
  }
}

VALUE Object::GetPropertyAttributes(VALUE self, VALUE key) {
  return PropertyAttribute(Object(self)->GetPropertyAttributes(Value(key)));
}

VALUE Object::Has(VALUE self, VALUE key) {
  Object obj(self);
  if (rb_obj_is_kind_of(key, rb_cNumeric)) {
    return Bool(obj->Has(UInt32(key)));
  } else {
    return Bool(obj->Has(*String(key)));
  }
}

VALUE Object::Delete(VALUE self, VALUE key) {
  Object obj(self);
  if (rb_obj_is_kind_of(key, rb_cNumeric)) {
    return Bool(obj->Delete(UInt32(key)));
  } else {
    return Bool(obj->Delete(*String(key)));
  }
}

VALUE Object::ForceDelete(VALUE self, VALUE key) {
  return Bool(Object(self)->ForceDelete(Value(key)));
}


VALUE Object::SetAccessor(int argc, VALUE* argv, VALUE self) {
  VALUE name; VALUE get; VALUE set; VALUE data; VALUE settings; VALUE attribs;
  rb_scan_args(argc, argv, "24", &name, &get, &set, &data, &settings, &attribs);
  Accessor access(get, set, data);
  return Bool(Object(self)->SetAccessor(
    String(name),
    access.accessorGetter(),
    access.accessorSetter(),
    access,
    AccessControl(settings),
    PropertyAttribute(attribs))
  );
}

Object::operator VALUE() {
  if (handle.IsEmpty()) {
    return Qnil;
  }
  Backref* backref;
  v8::Local<v8::String> key(v8::String::NewSymbol("rr::Backref"));
  v8::Local<v8::Value> external = handle->GetHiddenValue(key);
  VALUE value;
  if (external.IsEmpty()) {
    value = downcast();
    backref = new Backref(value);
    handle->SetHiddenValue(key, backref->toExternal());
  } else {
    v8::Local<v8::External> wrapper = v8::External::Cast(*external);
    backref = (Backref*)wrapper->Value();
    value = backref->get();
    if (!RTEST(value)) {
      value = downcast();
      backref->set(value);
    }
  }
  return value;
}

VALUE Object::downcast() {
  if (handle->IsFunction()) {
    return Function((v8::Handle<v8::Function>) v8::Function::Cast(*handle));
  }
  if (handle->IsArray()) {
    return Array((v8::Handle<v8::Array>)v8::Array::Cast(*handle));
  }
  if (handle->IsDate()) {
    // return Date(handle);
  }
  if (handle->IsBooleanObject()) {
    // return BooleanObject(handle);
  }
  if (handle->IsNumberObject()) {
    // return NumberObject(handle);
  }
  if (handle->IsStringObject()) {
    // return StringObject(handle);
  }
  if (handle->IsRegExp()) {
    // return RegExp(handle);
  }
  return Ref<v8::Object>::operator VALUE();
}

VALUE Object::GetPropertyNames(VALUE self) {
  return Array(Object(self)->GetPropertyNames());
}

VALUE Object::GetOwnPropertyNames(VALUE self) {
  return Array(Object(self)->GetOwnPropertyNames());
}

VALUE Object::GetPrototype(VALUE self) {
  return Value(Object(self)->GetPrototype());
}

VALUE Object::SetPrototype(VALUE self, VALUE prototype) {
  return Bool(Object(self)->SetPrototype(Value(prototype)));
}

VALUE Object::FindInstanceInPrototypeChain(VALUE self, VALUE impl) {
  return Object(Object(self)->FindInstanceInPrototypeChain(FunctionTemplate(impl)));
}

VALUE Object::ObjectProtoToString(VALUE self) {
  return String(Object(self)->ObjectProtoToString());
}

VALUE Object::GetConstructorName(VALUE self) {
  return String(Object(self)->GetConstructorName());
}

VALUE Object::InternalFieldCount(VALUE self) {
  return INT2FIX(Object(self)->InternalFieldCount());
}

VALUE Object::GetInternalField(VALUE self, VALUE idx) {
  return Value(Object(self)->GetInternalField(NUM2INT(idx)));
}

VALUE Object::SetInternalField(VALUE self, VALUE idx, VALUE value) {
  Void(Object(self)->SetInternalField(NUM2INT(idx), Value(value)));
}

VALUE Object::HasOwnProperty(VALUE self, VALUE key) {
  return Bool(Object(self)->HasOwnProperty(String(key)));
}

VALUE Object::HasRealNamedProperty(VALUE self, VALUE key) {
  return Bool(Object(self)->HasRealNamedProperty(String(key)));
}

VALUE Object::HasRealIndexedProperty(VALUE self, VALUE idx) {
  return Bool(Object(self)->HasRealIndexedProperty(UInt32(idx)));
}

VALUE Object::HasRealNamedCallbackProperty(VALUE self, VALUE key) {
  return Bool(Object(self)->HasRealNamedCallbackProperty(String(key)));
}

VALUE Object::GetRealNamedPropertyInPrototypeChain(VALUE self, VALUE key) {
  return Value(Object(self)->GetRealNamedPropertyInPrototypeChain(String(key)));
}

VALUE Object::GetRealNamedProperty(VALUE self, VALUE key) {
  return Value(Object(self)->GetRealNamedProperty(String(key)));
}

VALUE Object::HasNamedLookupInterceptor(VALUE self) {
  return Bool(Object(self)->HasNamedLookupInterceptor());
}

VALUE Object::HasIndexedLookupInterceptor(VALUE self) {
  return Bool(Object(self)->HasIndexedLookupInterceptor());
}

VALUE Object::TurnOnAccessCheck(VALUE self) {
  Void(Object(self)->TurnOnAccessCheck());
}

VALUE Object::GetIdentityHash(VALUE self) {
  return INT2FIX(Object(self)->GetIdentityHash());
}

VALUE Object::SetHiddenValue(VALUE self, VALUE key, VALUE value) {
  return Bool(Object(self)->SetHiddenValue(String(key), Value(value)));
}

VALUE Object::GetHiddenValue(VALUE self, VALUE key) {
  return Value(Object(self)->GetHiddenValue(String(key)));
}

VALUE Object::DeleteHiddenValue(VALUE self, VALUE key) {
  return Bool(Object(self)->DeleteHiddenValue(String(key)));
}

VALUE Object::IsDirty(VALUE self) {
  return Bool(Object(self)->IsDirty());
}

VALUE Object::Clone(VALUE self) {
  return Object(Object(self)->Clone());
}

VALUE Object::CreationContext(VALUE self) {
  return Context(Object(self)->CreationContext());
}

VALUE Object::SetIndexedPropertiesToPixelData(VALUE self, VALUE data, VALUE length) {
  return not_implemented("SetIndexedPropertiesToPixelData");
}

VALUE Object::GetIndexedPropertiesPixelData(VALUE self) {
  return not_implemented("GetIndexedPropertiesPixelData");
}

VALUE Object::HasIndexedPropertiesInPixelData(VALUE self) {
  return Bool(Object(self)->HasIndexedPropertiesInPixelData());
}

VALUE Object::GetIndexedPropertiesPixelDataLength(VALUE self) {
  return INT2FIX(Object(self)->GetIndexedPropertiesPixelDataLength());
}

VALUE Object::SetIndexedPropertiesToExternalArrayData(VALUE self) {
  return not_implemented("SetIndexedPropertiesToExternalArrayData");
}

VALUE Object::HasIndexedPropertiesInExternalArrayData(VALUE self) {
  return Bool(Object(self)->HasIndexedPropertiesInExternalArrayData());
}

VALUE Object::GetIndexedPropertiesExternalArrayData(VALUE self) {
  return not_implemented("GetIndexedPropertiesExternalArrayData");
}

VALUE Object::GetIndexedPropertiesExternalArrayDataType(VALUE self) {
  return not_implemented("GetIndexedPropertiesExternalArrayDataType");
}

VALUE Object::GetIndexedPropertiesExternalArrayDataLength(VALUE self) {
  return INT2FIX(Object(self)->GetIndexedPropertiesExternalArrayDataLength());
}

VALUE Object::IsCallable(VALUE self) {
  return Bool(Object(self)->IsCallable());
}

VALUE Object::CallAsFunction(VALUE self, VALUE recv, VALUE argv) {
  return Value(Object(self)->CallAsFunction(Object(recv), RARRAY_LENINT(argv), Value::array<Value>(argv)));
}

VALUE Object::CallAsConstructor(VALUE self, VALUE argv) {
  return Value(Object(self)->CallAsConstructor(RARRAY_LENINT(argv), Value::array<Value>(argv)));
}

}
