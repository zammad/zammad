#include "rr.h"

namespace rr {

VALUE Value::Empty;

void Value::Init() {
  Empty = rb_eval_string("Object.new");
  ClassBuilder("Value").
    defineConst("Empty", Empty).
    defineMethod("IsUndefined", &IsUndefined).
    defineMethod("IsNull", &IsNull).
    defineMethod("IsTrue", &IsTrue).
    defineMethod("IsFalse", &IsFalse).
    defineMethod("IsString", &IsString).
    defineMethod("IsFunction", &IsFunction).
    defineMethod("IsArray", &IsArray).
    defineMethod("IsObject", &IsObject).
    defineMethod("IsBoolean", &IsBoolean).
    defineMethod("IsNumber", &IsNumber).
    defineMethod("IsExternal", &IsExternal).
    defineMethod("IsInt32", &IsInt32).
    defineMethod("IsUint32", &IsUint32).
    defineMethod("IsDate", &IsDate).
    defineMethod("IsBooleanObject", &IsBooleanObject).
    defineMethod("IsNumberObject", &IsNumberObject).
    defineMethod("IsStringObject", &IsStringObject).
    defineMethod("IsNativeError", &IsNativeError).
    defineMethod("IsRegExp", &IsRegExp).
    defineMethod("ToString", &ToString).
    defineMethod("ToDetailString", &ToDetailString).
    defineMethod("ToObject", &ToObject).
    defineMethod("BooleanValue", &BooleanValue).
    defineMethod("NumberValue", &NumberValue).
    defineMethod("IntegerValue", &IntegerValue).
    defineMethod("Uint32Value", &Uint32Value).
    defineMethod("IntegerValue", &IntegerValue).
    defineMethod("Equals", &Equals).
    defineMethod("StrictEquals", &StrictEquals)
    .store(&Class);
    rb_gc_register_address(&Empty);
}

 VALUE Value::IsUndefined(VALUE self) {
   return Bool(Value(self)->IsUndefined());
 }
 VALUE Value::IsNull(VALUE self) {
   return Bool(Value(self)->IsNull());
 }
 VALUE Value::IsTrue(VALUE self) {
   return Bool(Value(self)->IsTrue());
 }
 VALUE Value::IsFalse(VALUE self) {
   return Bool(Value(self)->IsFalse());
 }
 VALUE Value::IsString(VALUE self) {
   return Bool(Value(self)->IsString());
 }
 VALUE Value::IsFunction(VALUE self) {
   return Bool(Value(self)->IsFunction());
 }
 VALUE Value::IsArray(VALUE self) {
   return Bool(Value(self)->IsArray());
 }
 VALUE Value::IsObject(VALUE self) {
   return Bool(Value(self)->IsObject());
 }
 VALUE Value::IsBoolean(VALUE self) {
   return Bool(Value(self)->IsBoolean());
 }
 VALUE Value::IsNumber(VALUE self) {
   return Bool(Value(self)->IsNumber());
 }
 VALUE Value::IsExternal(VALUE self) {
   return Bool(Value(self)->IsExternal());
 }
 VALUE Value::IsInt32(VALUE self) {
   return Bool(Value(self)->IsInt32());
 }
 VALUE Value::IsUint32(VALUE self) {
   return Bool(Value(self)->IsUint32());
 }
 VALUE Value::IsDate(VALUE self) {
   return Bool(Value(self)->IsDate());
 }
 VALUE Value::IsBooleanObject(VALUE self) {
   return Bool(Value(self)->IsBooleanObject());
 }
 VALUE Value::IsNumberObject(VALUE self) {
   return Bool(Value(self)->IsNumberObject());
 }
 VALUE Value::IsStringObject(VALUE self) {
   return Bool(Value(self)->IsStringObject());
 }
 VALUE Value::IsNativeError(VALUE self) {
   return Bool(Value(self)->IsNativeError());
 }
 VALUE Value::IsRegExp(VALUE self) {
   return Bool(Value(self)->IsRegExp());
 }

 // VALUE Value::ToBoolean(VALUE self) {
 //   return Boolean(Value(self)->ToBoolean());
 // }

 // VALUE Value::ToNumber(VALUE self) {
 //   return Number(Value(self)->ToNumber());
 // }
 VALUE Value::ToString(VALUE self) {
   return String(Value(self)->ToString());
 }

 VALUE Value::ToDetailString(VALUE self) {
   return String(Value(self)->ToDetailString());
 }

 VALUE Value::ToObject(VALUE self) {
   return Object(Value(self)->ToObject());
 }

 // VALUE Value::ToInteger(VALUE self) {
 //   return Integer(Value(self)->ToInteger());
 // }

 // VALUE Value::ToUint32(VALUE self) {
 //   return Uint32(Value(self)->ToUint32());
 // }

 // VALUE Value::ToInt32(VALUE self) {
 //   return Int32(Value(self)->ToInt32());
 // }


// VALUE Value::ToArrayIndex(VALUE self) {
//   return Uint32(Value(self)->ToArrayIndex());
// }

VALUE Value::BooleanValue(VALUE self) {
  return Bool(Value(self)->BooleanValue());
}
VALUE Value::NumberValue(VALUE self) {
  return rb_float_new(Value(self)->NumberValue());
}
VALUE Value::IntegerValue(VALUE self) {
  return INT2NUM(Value(self)->IntegerValue());
}
VALUE Value::Uint32Value(VALUE self) {
  return UINT2NUM(Value(self)->Uint32Value());
}
VALUE Value::Int32Value(VALUE self) {
  return INT2FIX(Value(self)->Int32Value());
}

VALUE Value::Equals(VALUE self, VALUE other) {
  return Bool(Value(self)->Equals(Value(other)));
}

VALUE Value::StrictEquals(VALUE self, VALUE other) {
  return Bool(Value(self)->StrictEquals(Value(other)));
}

Value::operator VALUE() {
  if (handle.IsEmpty() || handle->IsUndefined() || handle->IsNull()) {
    return Qnil;
  }
  if (handle->IsTrue()) {
    return Qtrue;
  }
  if (handle->IsFalse()) {
    return Qfalse;
  }
  if (handle->IsExternal()) {
    return External((v8::Handle<v8::External>)v8::External::Cast(*handle));
  }
  if (handle->IsUint32()) {
    return UInt32(handle->Uint32Value());
  }
  if (handle->IsInt32()) {
    return INT2FIX(handle->Int32Value());
  }
  if (handle->IsBoolean()) {
    return handle->BooleanValue() ? Qtrue : Qfalse;
  }
  if (handle->IsNumber()) {
    return rb_float_new(handle->NumberValue());
  }
  if (handle->IsString()) {
    return String(handle->ToString());
  }
  if (handle->IsDate()) {
    return Date((v8::Handle<v8::Date>)v8::Date::Cast(*handle));
  }
  if (handle->IsObject()) {
    return Object(handle->ToObject());
  }
  return Ref<v8::Value>::operator VALUE();
}

Value::operator v8::Handle<v8::Value>() const {
    if (rb_equal(value,Empty)) {
      return v8::Handle<v8::Value>();
    }
    switch (TYPE(value)) {
    case T_FIXNUM:
      return v8::Integer::New(NUM2INT(value));
    case T_FLOAT:
      return v8::Number::New(NUM2DBL(value));
    case T_STRING:
      return v8::String::New(RSTRING_PTR(value), (int)RSTRING_LEN(value));
    case T_NIL:
      return v8::Null();
    case T_TRUE:
      return v8::True();
    case T_FALSE:
      return v8::False();
    case T_DATA:
      return Ref<v8::Value>::operator v8::Handle<v8::Value>();
    case T_OBJECT:
    case T_CLASS:
    case T_ICLASS:
    case T_MODULE:
    case T_REGEXP:
    case T_MATCH:
    case T_ARRAY:
    case T_HASH:
    case T_STRUCT:
    case T_BIGNUM:
    case T_FILE:
    case T_SYMBOL:
    case T_UNDEF:
    case T_NODE:
    default:
      rb_warn("unknown conversion to V8 for: %s", RSTRING_PTR(rb_inspect(value)));
      return v8::String::New("Undefined Conversion");
    }

    return v8::Undefined();
}
}