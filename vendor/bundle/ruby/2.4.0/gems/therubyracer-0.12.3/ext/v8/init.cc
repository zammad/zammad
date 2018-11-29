#include "rr.h"

extern "C" {
  void Init_init();
}

using namespace rr;

extern "C" {
  void Init_init() {
    v8::Locker lock();
    GC::Init();
    V8::Init();
    Handles::Init();
    Accessor::Init();
    Context::Init();
    Invocation::Init();
    Signature::Init();
    Value::Init();
    Primitive::Init();
    String::Init();
    Object::Init();
    Array::Init();
    Function::Init();
    Date::Init();
    Constants::Init();
    External::Init();
    Script::Init();
    Template::Init();
    Stack::Init();
    Message::Init();
    TryCatch::Init();
    Exception::Init();
    Locker::Init();
    ResourceConstraints::Init();
    HeapStatistics::Init();
    Backref::Init();
  }
}