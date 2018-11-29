#ifndef THE_RUBY_RACER
#define THE_RUBY_RACER

#include <v8.h>
#include <ruby.h>
#include <vector>
#ifdef HAVE_RUBY_ENCODING_H
#include "ruby/encoding.h"
#endif

#if !defined(RARRAY_LENINT)
# define RARRAY_LENINT(v) (int)RARRAY_LEN(v)
#endif /* ! defined(RARRAY_LENINT) */

#if !defined(SIZET2NUM)
#  if SIZEOF_SIZE_T == SIZEOF_LONG
#    define SIZET2NUM(n) ULONG2NUM(n)
#  else
#    define SIZET2NUM(n) ULL2NUM(n)
#  endif
#endif /* ! defined(SIZET2NUM) */

#if !defined(NUM2SIZET)
#  if SIZEOF_SIZE_T == SIZEOF_LONG
#    define NUM2SIZET(n) ((size_t)NUM2ULONG(n))
#  else
#    define NUM2SIZET(n) ((size_t)NUM2ULL(n))
#  endif
#endif /* ! defined(NUM2SIZET) */

namespace rr {

#define Void(expr) expr; return Qnil;
VALUE not_implemented(const char* message);

class Equiv {
public:
  Equiv(VALUE val) : value(val) {}
  inline operator VALUE() {return value;}
protected:
  VALUE value;
};

class Bool : public Equiv {
public:
  Bool(VALUE val) : Equiv(val) {}
  Bool(bool b) : Equiv(b ? Qtrue : Qfalse) {}
  Bool(v8::Handle<v8::Boolean> b) : Equiv(b->Value() ? Qtrue : Qfalse) {}
  inline operator bool() {return RTEST(value);}
};

class UInt32 : public Equiv {
public:
  UInt32(VALUE val) : Equiv(val) {}
  UInt32(uint32_t ui) : Equiv(UINT2NUM(ui)) {}
  inline operator uint32_t() {return RTEST(value) ? NUM2UINT(value) : 0;}
};

class GC {
public:
  class Queue {
  public:
    Queue();
    void Enqueue(void* phantom);
    void* Dequeue();
    private:
      struct Node {
        Node(void* val ) : value(val), next(NULL) { }
        void* value;
        Node* next;
      };
      Node* first;      // for producer only
      Node* divider;
      Node* last;
  };
  static void Finalize(void* phantom);
  static void Drain(v8::GCType type, v8::GCCallbackFlags flags);
  static void Init();
};

/**
* A V8 Enum
*/

template <class T> class Enum : public Equiv {
public:
  Enum<T>(VALUE value, T defaultValue = 0) : Equiv(value) {
    this->defaultValue = defaultValue;
  }
  inline operator T() {
    return (T)(RTEST(value) ? NUM2INT(value) : defaultValue);
  }
private:
  T defaultValue;
};

/**
* A pointer to V8 object managed by Ruby
*
* You deal with V8 objects as either pointers or handles.
* While handles are managed by the V8 garbage collector, pointers
* must be explicitly created and destroyed by your code.
*
* The pointer class provides a handly way to wrap V8 pointers
* into Ruby objects so that they will be deleted when the
* Ruby object is garbage collected. Automatic type coercion is
* used to make wrapping and unwrapping painless.
*
* To create Ruby VALUE:
*
*  Pointer<v8::ScriptOrigin> ptr(new v8::ScriptOrigin());
*  VALUE value = ptr; //automatically wraps in Data_Wrap_Struct
*
* Conversely, the pointer can be unwrapped from a struct
* created in this way and the underlying methods can be
* invoked:
*
*     VALUE value = ...;
*     Pointer<v8::ScriptOrigin> ptr(value);
*     ptr->CallMethod();
*/

template <class T> class Pointer {
public:
  inline Pointer(T* t) : pointer(t) {};
  inline Pointer(VALUE v) {
    if (RTEST(v)) {
      this->unwrap(v);
    } else {
      this->pointer = NULL;
    }
  };
  inline operator T*() {return pointer;}
  inline T* operator ->() {return pointer;}
  inline operator VALUE() {
    return Data_Wrap_Struct(Class, 0, &release, pointer);
  }
  void unwrap(VALUE value);
  static void release(T* pointer) {
    delete pointer;
  }
  static VALUE Class;
protected:
  T* pointer;
};
template <class T> VALUE Pointer<T>::Class;

/**
* A Reference to a V8 managed object
*
* Uses type coercion to quickly convert from a v8 handle
* to a ruby object and back again. Suppose we have a v8 handle
* that we want to return to Ruby. We can put it into a Ref:
*
*     v8::Handle<v8::Object> object = v8::Object::New();
*     VALUE val = Ref<v8::Object>(object);
*
* this will create a `v8::Persistent` handle for the object
* so that it will not be garbage collected by v8. It then
* stuffs this new persistent handle into a Data_Wrap_Struct
* which can then be passed to Ruby code. When this struct
* is garbage collected by Ruby, it enqueues the corresponding
* v8 handle to be released during v8 gc.
*
* By the same token, you can use Refs to unwrap a Data_Wrap_Struct
* which has been generated in this fashion and call through to
* the underlying v8 methods. Suppose we are passed a VALUE `val`
* wrapping a v8::Object:
*
*     Ref<v8::Object> object(val);
*     object->Get(v8::String::New("foo"));
*
*/
template <class T> class Ref {
public:
  Ref(VALUE value) {
    this->value = value;
  }
  Ref(v8::Handle<T> handle, const char* label = "v8::Handle<void>") {
    this->handle = handle;
  }
  virtual ~Ref() {}
  /*
  *  Coerce a Ref into a Ruby VALUE
  */
  virtual operator VALUE() const {
    return handle.IsEmpty() ? Qnil : Data_Wrap_Struct(Class, 0, &Holder::enqueue, new Holder(handle));
  }
  /*
  * Coerce a Ref into a v8::Handle.
  */
  virtual operator v8::Handle<T>() const {
    if (RTEST(this->value)) {
      Holder* holder = NULL;
      Data_Get_Struct(this->value, class Holder, holder);
      return holder->handle;
    } else {
      return v8::Handle<T>();
    }
  }
  void dispose() {
    Holder* holder = NULL;
    Data_Get_Struct(this->value, class Holder, holder);
    holder->dispose();
  }

  /*
  * Pointer de-reference operators, this lets you use a ref to
  * call through to underlying v8 methods. e.g
  *
  *     Ref<v8::Object>(value)->ToString();
  */
  inline v8::Handle<T> operator->() const { return *this;}
  inline v8::Handle<T> operator*() const {return *this;}

  template <class C> class array {
  public:
    inline array(VALUE ary) : argv(ary), vector(RARRAY_LENINT(argv)) {}
    inline operator v8::Handle<T>*() {
      for (uint32_t i = 0; i < vector.size(); i++) {
        vector[i] = C(rb_ary_entry(argv, i));
      }
      return &vector[0];
    }
  private:
    VALUE argv;
    std::vector< v8::Handle<T> > vector;
  };

  class Holder {
    friend class Ref;
  public:
    Holder(v8::Handle<T> handle) {
      this->disposed_p = false;
      this->handle = v8::Persistent<T>::New(handle);
    }
    virtual ~Holder() {
      this->dispose();
    }
    void dispose() {
      if (!this->disposed_p) {
        handle.Dispose();
        this->disposed_p = true;
      }
    }
  protected:
    v8::Persistent<T> handle;
    bool disposed_p;

    static void enqueue(Holder* holder) {
      GC::Finalize(holder);
    }
  };

  VALUE value;
  v8::Handle<T> handle;
  static VALUE Class;
};
template <class T> VALUE Ref<T>::Class;

class Backref {
public:
  static void Init();
  Backref(VALUE value);
  virtual ~Backref();
  VALUE get();
  VALUE set(VALUE value);
  v8::Handle<v8::Value> toExternal();
  static void release(v8::Persistent<v8::Value> handle, void* data);
private:
  VALUE storage;
  static VALUE Storage;
  static ID _new;
  static ID object;
};
class Handles {
public:
  static void Init();
  static VALUE HandleScope(int argc, VALUE* argv, VALUE self);
private:
  static VALUE SetupAndCall(int* state, VALUE code);
  static VALUE DoCall(VALUE code);
};

class Phantom {
public:
  inline Phantom(void* reference) : holder((Ref<void>::Holder*)reference) {}
  inline bool NotNull() {
    return this->holder != NULL;
  }
  inline void destroy() {
    delete holder;
  }
  Ref<void>::Holder* holder;
};

class ExtensionConfiguration : public Pointer<v8::ExtensionConfiguration> {
public:
  static VALUE initialize(VALUE self, VALUE names);
  inline ExtensionConfiguration(v8::ExtensionConfiguration* config) : Pointer<v8::ExtensionConfiguration>(config) {}
  inline ExtensionConfiguration(VALUE value) : Pointer<v8::ExtensionConfiguration>(value) {}
};

class Context : public Ref<v8::Context> {
public:
  static void Init();
  static VALUE New(int argc, VALUE argv[], VALUE self);
  static VALUE Dispose(VALUE self);
  static VALUE Enter(VALUE self);
  static VALUE Exit(VALUE self);
  static VALUE Global(VALUE self);
  static VALUE DetachGlobal(VALUE self);
  static VALUE ReattachGlobal(VALUE self, VALUE global);
  static VALUE GetEntered(VALUE self);
  static VALUE GetCurrent(VALUE self);
  static VALUE GetCalling(VALUE self);
  static VALUE SetSecurityToken(VALUE self, VALUE token);
  static VALUE UseDefaultSecurityToken(VALUE self);
  static VALUE GetSecurityToken(VALUE self);
  static VALUE HasOutOfMemoryException(VALUE self);
  static VALUE InContext(VALUE self);
  static VALUE SetEmbedderData(VALUE self, VALUE index, VALUE data);
  static VALUE GetEmbedderData(VALUE self, VALUE index);
  static VALUE AllowCodeGenerationFromStrings(VALUE self, VALUE allow);
  static VALUE IsCodeGenerationFromStringsAllowed(VALUE self);

  inline Context(VALUE value) : Ref<v8::Context>(value) {}
  inline Context(v8::Handle<v8::Context> cxt) : Ref<v8::Context>(cxt) {}
};

class External: public Ref<v8::External> {
public:
  static void Init();
  static VALUE New(VALUE self, VALUE data);
  static VALUE Value(VALUE self);

  inline External(VALUE value) : Ref<v8::External>(value) {}
  inline External(v8::Handle<v8::External> ext) : Ref<v8::External>(ext) {}
  static v8::Handle<v8::External> wrap(VALUE data);
  static VALUE unwrap(v8::Handle<v8::External> external);
private:
  static void release(v8::Persistent<v8::Value> object, void* parameter);
  struct Data {
    Data(VALUE data);
    ~Data();
    VALUE value;
  };
};

class ScriptOrigin : public Pointer<v8::ScriptOrigin> {
public:
  inline ScriptOrigin(v8::ScriptOrigin* o) : Pointer<v8::ScriptOrigin>(o) {};
  inline ScriptOrigin(VALUE value) : Pointer<v8::ScriptOrigin>(value) {}

  static VALUE initialize(int argc, VALUE argv[], VALUE self);
};

class ScriptData : public Pointer<v8::ScriptData> {
public:
  inline ScriptData(v8::ScriptData* d) : Pointer<v8::ScriptData>(d) {};
  inline ScriptData(VALUE value) : Pointer<v8::ScriptData>(value) {}

  static VALUE PreCompile(VALUE self, VALUE input, VALUE length);
  static VALUE New(VALUE self, VALUE data, VALUE length);
  static VALUE Length(VALUE self);
  static VALUE Data(VALUE self);
  static VALUE HasError(VALUE self);
};

class Script : public Ref<v8::Script> {
public:
  static void Init();
  static VALUE New(int argc, VALUE argv[], VALUE self);
  static VALUE Run(VALUE self);
  static VALUE RunWithTimeout(VALUE self, VALUE timeout);

  inline Script(VALUE value) : Ref<v8::Script>(value) {}
  inline Script(v8::Handle<v8::Script> script) : Ref<v8::Script>(script) {}
};

class Value : public Ref<v8::Value> {
public:
  static void Init();
  static VALUE IsUndefined(VALUE self);
  static VALUE IsNull(VALUE self);
  static VALUE IsTrue(VALUE self);
  static VALUE IsFalse(VALUE self);
  static VALUE IsString(VALUE self);
  static VALUE IsFunction(VALUE self);
  static VALUE IsArray(VALUE self);
  static VALUE IsObject(VALUE self);
  static VALUE IsBoolean(VALUE self);
  static VALUE IsNumber(VALUE self);
  static VALUE IsExternal(VALUE self);
  static VALUE IsInt32(VALUE self);
  static VALUE IsUint32(VALUE self);
  static VALUE IsDate(VALUE self);
  static VALUE IsBooleanObject(VALUE self);
  static VALUE IsNumberObject(VALUE self);
  static VALUE IsStringObject(VALUE self);
  static VALUE IsNativeError(VALUE self);
  static VALUE IsRegExp(VALUE self);
  // VALUE ToBoolean(VALUE self);
  // VALUE ToNumber(VALUE self);
  static VALUE ToString(VALUE self);
  static VALUE ToDetailString(VALUE self);
  static VALUE ToObject(VALUE self);
  // static VALUE ToInteger(VALUE self);
  // static VALUE ToUint32(VALUE self);
  // static VALUE ToInt32(VALUE self);
  // static VALUE ToArrayIndex(VALUE self);
  static VALUE BooleanValue(VALUE self);
  static VALUE NumberValue(VALUE self);
  static VALUE IntegerValue(VALUE self);
  static VALUE Uint32Value(VALUE self);
  static VALUE Int32Value(VALUE self);

  static VALUE Equals(VALUE self, VALUE other);
  static VALUE StrictEquals(VALUE self, VALUE other);
  inline Value(VALUE value) : Ref<v8::Value>(value) {}
  inline Value(v8::Handle<v8::Value> value) : Ref<v8::Value>(value) {}
  virtual operator VALUE();
  virtual operator v8::Handle<v8::Value>() const;
  static VALUE Empty;
};

class Primitive: public Ref<v8::Primitive> {
public:
  static void Init();
  inline Primitive(VALUE value) : Ref<v8::Primitive>(value) {}
  inline Primitive(v8::Handle<v8::Primitive> primitive) : Ref<v8::Primitive>(primitive) {}
};

class String: public Ref<v8::String> {
public:
  static void Init();
  static VALUE New(VALUE self, VALUE value);
  static VALUE NewSymbol(VALUE self, VALUE string);
  static VALUE Utf8Value(VALUE self);
  static VALUE Concat(VALUE self, VALUE left, VALUE right);

  inline String(VALUE value) : Ref<v8::String>(value) {}
  inline String(v8::Handle<v8::String> string) : Ref<v8::String>(string) {}
  virtual operator v8::Handle<v8::String>() const;
};

class PropertyAttribute: public Enum<v8::PropertyAttribute> {
public:
  inline PropertyAttribute(VALUE value) : Enum<v8::PropertyAttribute>(value, v8::None) {}
};
class AccessControl: public Enum<v8::AccessControl> {
public:
  inline AccessControl(VALUE value) : Enum<v8::AccessControl>(value, v8::DEFAULT) {}
};

class Accessor {
public:
  static void Init();
  Accessor(VALUE get, VALUE set, VALUE data);
  Accessor(VALUE get, VALUE set, VALUE query, VALUE deleter, VALUE enumerator, VALUE data);
  Accessor(v8::Handle<v8::Value> value);

  inline v8::AccessorGetter accessorGetter() {return &AccessorGetter;}
  inline v8::AccessorSetter accessorSetter() {return RTEST(set) ? &AccessorSetter : 0;}

  inline v8::NamedPropertyGetter namedPropertyGetter() {return &NamedPropertyGetter;}
  inline v8::NamedPropertySetter namedPropertySetter() {return RTEST(set) ? &NamedPropertySetter : 0;}
  inline v8::NamedPropertyQuery namedPropertyQuery() {return RTEST(query) ? &NamedPropertyQuery : 0;}
  inline v8::NamedPropertyDeleter namedPropertyDeleter() {return RTEST(deleter) ? &NamedPropertyDeleter : 0;}
  inline v8::NamedPropertyEnumerator namedPropertyEnumerator() {return RTEST(enumerator) ? &NamedPropertyEnumerator : 0;}

  inline v8::IndexedPropertyGetter indexedPropertyGetter() {return &IndexedPropertyGetter;}
  inline v8::IndexedPropertySetter indexedPropertySetter() {return RTEST(set) ? &IndexedPropertySetter : 0;}
  inline v8::IndexedPropertyQuery indexedPropertyQuery() {return RTEST(query) ? &IndexedPropertyQuery : 0;}
  inline v8::IndexedPropertyDeleter indexedPropertyDeleter() {return RTEST(deleter) ? &IndexedPropertyDeleter : 0;}
  inline v8::IndexedPropertyEnumerator indexedPropertyEnumerator() {return RTEST(enumerator) ? &IndexedPropertyEnumerator : 0;}

  operator v8::Handle<v8::Value>();

  class Info {
  public:
    Info(const v8::AccessorInfo& info);
    Info(VALUE value);
    static VALUE This(VALUE self);
    static VALUE Holder(VALUE self);
    static VALUE Data(VALUE self);
    operator VALUE();
    inline const v8::AccessorInfo* operator->() {return this->info;}
    v8::Handle<v8::Value> get(v8::Local<v8::String> property);
    v8::Handle<v8::Value> set(v8::Local<v8::String> property, v8::Local<v8::Value> value);
    v8::Handle<v8::Integer> query(v8::Local<v8::String> property);
    v8::Handle<v8::Boolean> remove(v8::Local<v8::String> property);
    v8::Handle<v8::Array> enumerateNames();
    v8::Handle<v8::Value> get(uint32_t index);
    v8::Handle<v8::Value> set(uint32_t index, v8::Local<v8::Value> value);
    v8::Handle<v8::Integer> query(uint32_t index);
    v8::Handle<v8::Boolean> remove(uint32_t index);
    v8::Handle<v8::Array> enumerateIndices();

    static VALUE Class;
  private:
    const v8::AccessorInfo* info;
  };
  friend class Info;
private:
  static v8::Handle<v8::Value> AccessorGetter(v8::Local<v8::String> property, const v8::AccessorInfo& info);
  static void AccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info);

  static v8::Handle<v8::Value> NamedPropertyGetter(v8::Local<v8::String> property, const v8::AccessorInfo& info);
  static v8::Handle<v8::Value> NamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
  static v8::Handle<v8::Integer> NamedPropertyQuery(v8::Local<v8::String> property, const v8::AccessorInfo& info);
  static v8::Handle<v8::Boolean> NamedPropertyDeleter(v8::Local<v8::String> property, const v8::AccessorInfo& info);
  static v8::Handle<v8::Array> NamedPropertyEnumerator(const v8::AccessorInfo& info);

  static v8::Handle<v8::Value> IndexedPropertyGetter(uint32_t index, const v8::AccessorInfo& info);
  static v8::Handle<v8::Value> IndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
  static v8::Handle<v8::Integer> IndexedPropertyQuery(uint32_t index, const v8::AccessorInfo& info);
  static v8::Handle<v8::Boolean> IndexedPropertyDeleter(uint32_t index, const v8::AccessorInfo& info);
  static v8::Handle<v8::Array> IndexedPropertyEnumerator(const v8::AccessorInfo& info);

  void wrap(v8::Handle<v8::Object> wrapper, int index, VALUE value);
  VALUE unwrap(v8::Handle<v8::Object> wrapper, int index);
  VALUE get;
  VALUE set;
  VALUE query;
  VALUE deleter;
  VALUE enumerator;
  VALUE data;
};

class Invocation {
public:
  static void Init();
  Invocation(VALUE code, VALUE data);
  Invocation(v8::Handle<v8::Value> wrapper);
  operator v8::InvocationCallback();
  operator v8::Handle<v8::Value>();
  static v8::Handle<v8::Value> Callback(const v8::Arguments& args);

  class Arguments {
  public:
    static void Init();
    Arguments(const v8::Arguments& args);
    Arguments(VALUE value);
    inline const v8::Arguments* operator->() {return this->args;}
    inline const v8::Arguments operator*() {return *this->args;}
    v8::Handle<v8::Value> Call();

    static VALUE Length(VALUE self);
    static VALUE Get(VALUE self, VALUE index);
    static VALUE Callee(VALUE self);
    static VALUE This(VALUE self);
    static VALUE Holder(VALUE self);
    static VALUE IsConstructCall(VALUE self);
    static VALUE Data(VALUE self);
  private:
    const v8::Arguments* args;
    static VALUE Class;
  };
private:
  VALUE code;
  VALUE data;
  friend class Arguments;
};

class Object : public Ref<v8::Object> {
public:
  static void Init();
  static VALUE New(VALUE self);
  static VALUE Set(VALUE self, VALUE key, VALUE value);
  static VALUE ForceSet(VALUE self, VALUE key, VALUE value);
  static VALUE Get(VALUE self, VALUE key);
  static VALUE GetPropertyAttributes(VALUE self, VALUE key);
  static VALUE Has(VALUE self, VALUE key);
  static VALUE Delete(VALUE self, VALUE key);
  static VALUE ForceDelete(VALUE self, VALUE key);
  static VALUE SetAccessor(int argc, VALUE* argv, VALUE self);
  static VALUE GetPropertyNames(VALUE self);
  static VALUE GetOwnPropertyNames(VALUE self);
  static VALUE GetPrototype(VALUE self);
  static VALUE SetPrototype(VALUE self, VALUE prototype);
  static VALUE FindInstanceInPrototypeChain(VALUE self, VALUE impl);
  static VALUE ObjectProtoToString(VALUE self);
  static VALUE GetConstructorName(VALUE self);
  static VALUE InternalFieldCount(VALUE self);
  static VALUE GetInternalField(VALUE self, VALUE idx);
  static VALUE SetInternalField(VALUE self, VALUE idx, VALUE value);
  static VALUE HasOwnProperty(VALUE self, VALUE key);
  static VALUE HasRealNamedProperty(VALUE self, VALUE key);
  static VALUE HasRealIndexedProperty(VALUE self, VALUE idx);
  static VALUE HasRealNamedCallbackProperty(VALUE self, VALUE key);
  static VALUE GetRealNamedPropertyInPrototypeChain(VALUE self, VALUE key);
  static VALUE GetRealNamedProperty(VALUE self, VALUE key);
  static VALUE HasNamedLookupInterceptor(VALUE self);
  static VALUE HasIndexedLookupInterceptor(VALUE self);
  static VALUE TurnOnAccessCheck(VALUE self);
  static VALUE GetIdentityHash(VALUE self);
  static VALUE SetHiddenValue(VALUE self, VALUE key, VALUE value);
  static VALUE GetHiddenValue(VALUE self, VALUE key);
  static VALUE DeleteHiddenValue(VALUE self, VALUE key);
  static VALUE IsDirty(VALUE self);
  static VALUE Clone(VALUE self);
  static VALUE CreationContext(VALUE self);
  static VALUE SetIndexedPropertiesToPixelData(VALUE self, VALUE data, VALUE length);
  static VALUE GetIndexedPropertiesPixelData(VALUE self);
  static VALUE HasIndexedPropertiesInPixelData(VALUE self);
  static VALUE GetIndexedPropertiesPixelDataLength(VALUE self);
  static VALUE SetIndexedPropertiesToExternalArrayData(VALUE self);
  static VALUE HasIndexedPropertiesInExternalArrayData(VALUE self);
  static VALUE GetIndexedPropertiesExternalArrayData(VALUE self);
  static VALUE GetIndexedPropertiesExternalArrayDataType(VALUE self);
  static VALUE GetIndexedPropertiesExternalArrayDataLength(VALUE self);
  static VALUE IsCallable(VALUE self);
  static VALUE CallAsFunction(VALUE self, VALUE recv, VALUE argv);
  static VALUE CallAsConstructor(VALUE self, VALUE argv);

  inline Object(VALUE value) : Ref<v8::Object>(value) {}
  inline Object(v8::Handle<v8::Object> object) : Ref<v8::Object>(object) {}
  virtual operator VALUE();

protected:
  VALUE downcast();
};

class Array : public Ref<v8::Array> {
public:
  static void Init();
  static VALUE New(int argc, VALUE argv[], VALUE self);
  static VALUE Length(VALUE self);
  static VALUE CloneElementAt(VALUE self, VALUE index);

  inline Array(v8::Handle<v8::Array> array) : Ref<v8::Array>(array) {}
  inline Array(VALUE value) : Ref<v8::Array>(value) {}
};

class Function : public Ref<v8::Function> {
public:
  static void Init();
  static VALUE NewInstance(int argc, VALUE argv[], VALUE self);
  static VALUE Call(VALUE self, VALUE receiver, VALUE argv);
  static VALUE SetName(VALUE self, VALUE name);
  static VALUE GetName(VALUE self);
  static VALUE GetInferredName(VALUE self);
  static VALUE GetScriptLineNumber(VALUE self);
  static VALUE GetScriptColumnNumber(VALUE self);
  static VALUE GetScriptId(VALUE self);
  static VALUE GetScriptOrigin(VALUE self);

  inline Function(VALUE value) : Ref<v8::Function>(value) {}
  inline Function(v8::Handle<v8::Function> function) : Ref<v8::Function>(function) {}
};

class Date : public Ref<v8::Date> {
public:
  static void Init();
  static VALUE New(VALUE self, VALUE time);
  static VALUE NumberValue(VALUE self);

  inline Date(VALUE value) : Ref<v8::Date>(value) {}
  inline Date(v8::Handle<v8::Date> date) : Ref<v8::Date>(date) {}
};

class Signature : public Ref<v8::Signature> {
public:
  static void Init();
  static VALUE New(int argc, VALUE argv[], VALUE self);

  inline Signature(v8::Handle<v8::Signature> sig) : Ref<v8::Signature>(sig) {}
  inline Signature(VALUE value) : Ref<v8::Signature>(value) {}
};

class Template : public Ref<v8::Template> {
public:
  static void Init();
  static VALUE Set(int argc, VALUE argv[], VALUE self);
  inline Template(v8::Handle<v8::Template> t) : Ref<v8::Template>(t) {}
  inline Template(VALUE value) : Ref<v8::Template>(value) {}
};

class ObjectTemplate : public Ref<v8::ObjectTemplate> {
public:
  static void Init();
  static VALUE New(VALUE self);
  static VALUE NewInstance(VALUE self);
  static VALUE SetAccessor(int argc, VALUE argv[], VALUE self);
  static VALUE SetNamedPropertyHandler(int argc, VALUE argv[], VALUE self);
  static VALUE SetIndexedPropertyHandler(int argc, VALUE argv[], VALUE self);
  static VALUE SetCallAsFunctionHandler(int argc, VALUE argv[], VALUE self);
  static VALUE MarkAsUndetectable(VALUE self);
  static VALUE SetAccessCheckCallbacks(int argc, VALUE argv[], VALUE self);
  static VALUE InternalFieldCount(VALUE self);
  static VALUE SetInternalFieldCount(VALUE self, VALUE count);

  inline ObjectTemplate(VALUE value) : Ref<v8::ObjectTemplate>(value) {}
  inline ObjectTemplate(v8::Handle<v8::ObjectTemplate> t) : Ref<v8::ObjectTemplate>(t) {}
};

class FunctionTemplate : public Ref<v8::FunctionTemplate> {
public:
  static void Init();
  static VALUE New(int argc, VALUE argv[], VALUE self);
  static VALUE GetFunction(VALUE self);
  static VALUE SetCallHandler(int argc, VALUE argv[], VALUE self);
  static VALUE InstanceTemplate(VALUE self);
  static VALUE Inherit(VALUE self, VALUE parent);
  static VALUE PrototypeTemplate(VALUE self);
  static VALUE SetClassName(VALUE self, VALUE name);
  static VALUE SetHiddenPrototype(VALUE self, VALUE value);
  static VALUE ReadOnlyPrototype(VALUE self);
  static VALUE HasInstance(VALUE self, VALUE object);

  inline FunctionTemplate(VALUE value) : Ref<v8::FunctionTemplate>(value) {}
  inline FunctionTemplate(v8::Handle<v8::FunctionTemplate> t) : Ref<v8::FunctionTemplate>(t) {}
};

class Message : public Ref<v8::Message> {
public:
  static void Init();
  inline Message(v8::Handle<v8::Message> message) : Ref<v8::Message>(message) {}
  inline Message(VALUE value) : Ref<v8::Message>(value) {}

  static VALUE Get(VALUE self);
  static VALUE GetSourceLine(VALUE self);
  static VALUE GetScriptResourceName(VALUE self);
  static VALUE GetScriptData(VALUE self);
  static VALUE GetStackTrace(VALUE self);
  static VALUE GetLineNumber(VALUE self);
  static VALUE GetStartPosition(VALUE self);
  static VALUE GetEndPosition(VALUE self);
  static VALUE GetStartColumn(VALUE self);
  static VALUE GetEndColumn(VALUE self);
  static inline VALUE kNoLineNumberInfo(VALUE self) {return INT2FIX(v8::Message::kNoLineNumberInfo);}
  static inline VALUE kNoColumnInfo(VALUE self) {return INT2FIX(v8::Message::kNoColumnInfo);}
};

class Stack {
public:
  static void Init();

  class Trace : public Ref<v8::StackTrace> {
  public:
    class StackTraceOptions : public Enum<v8::StackTrace::StackTraceOptions> {
    public:
      inline StackTraceOptions(VALUE value) : Enum<v8::StackTrace::StackTraceOptions>(value, v8::StackTrace::kOverview) {}
    };
  public:
    inline Trace(v8::Handle<v8::StackTrace> trace) : Ref<v8::StackTrace>(trace) {}
    inline Trace(VALUE value) : Ref<v8::StackTrace>(value) {}
    static inline VALUE kLineNumber(VALUE self) {return INT2FIX(v8::StackTrace::kLineNumber);}
    static inline VALUE kColumnOffset(VALUE self) {return INT2FIX(v8::StackTrace::kColumnOffset);}
    static inline VALUE kScriptName(VALUE self) {return INT2FIX(v8::StackTrace::kScriptName);}
    static inline VALUE kFunctionName(VALUE self) {return INT2FIX(v8::StackTrace::kFunctionName);}
    static inline VALUE kIsEval(VALUE self) {return INT2FIX(v8::StackTrace::kIsEval);}
    static inline VALUE kIsConstructor(VALUE self) {return INT2FIX(v8::StackTrace::kIsConstructor);}
    static inline VALUE kScriptNameOrSourceURL(VALUE self) {return INT2FIX(v8::StackTrace::kScriptNameOrSourceURL);}
    static inline VALUE kOverview(VALUE self) {return INT2FIX(v8::StackTrace::kOverview);}
    static inline VALUE kDetailed(VALUE self) {return INT2FIX(v8::StackTrace::kDetailed);}

    static VALUE GetFrame(VALUE self, VALUE index);
    static VALUE GetFrameCount(VALUE self);
    static VALUE AsArray(VALUE self);
    static VALUE CurrentStackTrace(int argc, VALUE argv[], VALUE self);
  };
  class Frame : public Ref<v8::StackFrame> {
  public:
    inline Frame(v8::Handle<v8::StackFrame> frame) : Ref<v8::StackFrame>(frame) {}
    inline Frame(VALUE value) : Ref<v8::StackFrame>(value) {}
    static VALUE GetLineNumber(VALUE self);
    static VALUE GetColumn(VALUE self);
    static VALUE GetScriptName(VALUE self);
    static VALUE GetScriptNameOrSourceURL(VALUE self);
    static VALUE GetFunctionName(VALUE self);
    static VALUE IsEval(VALUE self);
    static VALUE IsConstructor(VALUE self);
  };
};

class TryCatch {
public:
  static void Init();
  TryCatch(v8::TryCatch*);
  TryCatch(VALUE value);
  operator VALUE();
  inline v8::TryCatch* operator->() {return this->impl;}
  static VALUE HasCaught(VALUE self);
  static VALUE CanContinue(VALUE self);
  static VALUE ReThrow(VALUE self);
  static VALUE Exception(VALUE self);
  static VALUE StackTrace(VALUE self);
  static VALUE Message(VALUE self);
  static VALUE Reset(VALUE self);
  static VALUE SetVerbose(VALUE self, VALUE value);
  static VALUE SetCaptureMessage(VALUE self, VALUE value);
private:
  static VALUE doTryCatch(int argc, VALUE argv[], VALUE self);
  static VALUE setupAndCall(int* state, VALUE code);
  static VALUE doCall(VALUE code);
  static VALUE Class;
  v8::TryCatch* impl;
};

class Locker {
public:
  static void Init();
  static VALUE StartPreemption(VALUE self, VALUE every_n_ms);
  static VALUE StopPreemption(VALUE self);
  static VALUE IsLocked(VALUE self);
  static VALUE IsActive(VALUE self);
  static VALUE doLock(int argc, VALUE* argv, VALUE self);
  static VALUE setupLockAndCall(int* state, VALUE code);
  static VALUE doLockCall(VALUE code);
  static VALUE doUnlock(int argc, VALUE* argv, VALUE self);
  static VALUE setupUnlockAndCall(int* state, VALUE code);
  static VALUE doUnlockCall(VALUE code);
};

class HeapStatistics : public Pointer<v8::HeapStatistics> {
public:
  static void Init();
  static VALUE initialize(VALUE self);
  static VALUE total_heap_size(VALUE self);
  static VALUE total_heap_size_executable(VALUE self);
  static VALUE total_physical_size(VALUE self);
  static VALUE used_heap_size(VALUE self);
  static VALUE heap_size_limit(VALUE self);

  inline HeapStatistics(v8::HeapStatistics* stats) : Pointer<v8::HeapStatistics>(stats) {}
  inline HeapStatistics(VALUE value) : Pointer<v8::HeapStatistics>(value) {}
};

class ResourceConstraints : Pointer<v8::ResourceConstraints> {
public:
  static void Init();
  static VALUE initialize(VALUE self);
  static VALUE max_young_space_size(VALUE self);
  static VALUE set_max_young_space_size(VALUE self, VALUE value);
  static VALUE max_old_space_size(VALUE self);
  static VALUE set_max_old_space_size(VALUE self, VALUE value);
  static VALUE max_executable_size(VALUE self);
  static VALUE set_max_executable_size(VALUE self, VALUE value);

  static VALUE SetResourceConstraints(VALUE self, VALUE constraints);

  inline ResourceConstraints(v8::ResourceConstraints* o) : Pointer<v8::ResourceConstraints>(o) {};
  inline ResourceConstraints(VALUE value) : Pointer<v8::ResourceConstraints>(value) {}
};

class Exception {
public:
  static void Init();
  static VALUE ThrowException(VALUE self, VALUE exception);
  static VALUE RangeError(VALUE self, VALUE message);
  static VALUE ReferenceError(VALUE self, VALUE message);
  static VALUE SyntaxError(VALUE self, VALUE message);
  static VALUE TypeError(VALUE self, VALUE message);
  static VALUE Error(VALUE self, VALUE message);
};

class Constants {
public:
  static void Init();
  static VALUE Undefined(VALUE self);
  static VALUE Null(VALUE self);
  static VALUE True(VALUE self);
  static VALUE False(VALUE self);

private:
  template <class R, class V> static VALUE cached(VALUE* storage, v8::Handle<V> value) {
    if (!RTEST(*storage)) {
      *storage = R(value);
    }
    return *storage;
  }
  static VALUE _Undefined;
  static VALUE _Null;
  static VALUE _True;
  static VALUE _False;
};

class V8 {
public:
  static void Init();
  static VALUE IdleNotification(int argc, VALUE argv[], VALUE self);
  static VALUE SetFlagsFromString(VALUE self, VALUE string);
  static VALUE SetFlagsFromCommandLine(VALUE self, VALUE args, VALUE remove_flags);
  static VALUE AdjustAmountOfExternalAllocatedMemory(VALUE self, VALUE change_in_bytes);
  static VALUE PauseProfiler(VALUE self);
  static VALUE ResumeProfiler(VALUE self);
  static VALUE IsProfilerPaused(VALUE self);
  static VALUE GetCurrentThreadId(VALUE self);
  static VALUE TerminateExecution(VALUE self, VALUE thread_id);
  static VALUE IsExecutionTerminating(VALUE self);
  static VALUE Dispose(VALUE self);
  static VALUE LowMemoryNotification(VALUE self);
  static VALUE ContextDisposedNotification(VALUE self);

  static VALUE SetCaptureStackTraceForUncaughtExceptions(int argc, VALUE argv[], VALUE self);
  static VALUE GetHeapStatistics(VALUE self, VALUE statistics_ptr);
  static VALUE GetVersion(VALUE self);
};

class ClassBuilder {
public:
  ClassBuilder() {};
  ClassBuilder(const char* name, VALUE superclass = rb_cObject);
  ClassBuilder(const char* name, const char* supername);
  ClassBuilder& defineConst(const char* name, VALUE value);
  ClassBuilder& defineMethod(const char* name, VALUE (*impl)(int, VALUE*, VALUE));
  ClassBuilder& defineMethod(const char* name, VALUE (*impl)(VALUE));
  ClassBuilder& defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE));
  ClassBuilder& defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE));
  ClassBuilder& defineMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE, VALUE));
  ClassBuilder& defineSingletonMethod(const char* name, VALUE (*impl)(int, VALUE*, VALUE));
  ClassBuilder& defineSingletonMethod(const char* name, VALUE (*impl)(VALUE));
  ClassBuilder& defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE));
  ClassBuilder& defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE));
  ClassBuilder& defineSingletonMethod(const char* name, VALUE (*impl)(VALUE, VALUE, VALUE, VALUE));
  ClassBuilder& defineEnumConst(const char* name, int value);
  ClassBuilder& store(VALUE* storage);
  inline operator VALUE() {return this->value;}
protected:
  VALUE value;
};

class ModuleBuilder : public ClassBuilder {
public:
  inline ModuleBuilder(const char* name) {
    this->value = rb_eval_string(name);
  }
};

}

#endif
