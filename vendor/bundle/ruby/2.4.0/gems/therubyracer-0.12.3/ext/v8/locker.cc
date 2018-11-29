#include "rr.h"

namespace rr {
  void Locker::Init() {
    ClassBuilder("Locker").
      defineSingletonMethod("StartPreemption", &StartPreemption).
      defineSingletonMethod("StopPreemption", &StopPreemption).
      defineSingletonMethod("IsLocked", &IsLocked).
      defineSingletonMethod("IsActive", &IsActive);
      VALUE v8 = rb_define_module("V8");
      VALUE c = rb_define_module_under(v8, "C");
      rb_define_singleton_method(c, "Locker", (VALUE (*)(...))&doLock, -1);
      rb_define_singleton_method(c, "Unlocker",(VALUE (*)(...))&doUnlock, -1);
  }

   VALUE Locker::StartPreemption(VALUE self, VALUE every_n_ms) {
     Void(v8::Locker::StartPreemption(NUM2INT(every_n_ms)));
   }

   VALUE Locker::StopPreemption(VALUE self) {
     Void(v8::Locker::StopPreemption());
   }

   VALUE Locker::IsLocked(VALUE self) {
     return Bool(v8::Locker::IsLocked(v8::Isolate::GetCurrent()));
   }

   VALUE Locker::IsActive(VALUE self) {
     return Bool(v8::Locker::IsActive());
   }

   VALUE Locker::doLock(int argc, VALUE* argv, VALUE self) {
     if (!rb_block_given_p()) {
       return Qnil;
     }
     int state = 0;
     VALUE code;
     rb_scan_args(argc,argv,"00&", &code);
     VALUE result = setupLockAndCall(&state, code);
     if (state != 0) {
       rb_jump_tag(state);
     }
     return result;
   }

   VALUE Locker::setupLockAndCall(int* state, VALUE code) {
     v8::Locker locker;
     return rb_protect(&doLockCall, code, state);
   }

   VALUE Locker::doLockCall(VALUE code) {
     return rb_funcall(code, rb_intern("call"), 0);
   }

   VALUE Locker::doUnlock(int argc, VALUE* argv, VALUE self) {
     if (!rb_block_given_p()) {
       return Qnil;
     }
     int state = 0;
     VALUE code;
     rb_scan_args(argc,argv,"00&", &code);
     VALUE result = setupUnlockAndCall(&state, code);
     if (state != 0) {
       rb_jump_tag(state);
     }
     return result;
   }

   VALUE Locker::setupUnlockAndCall(int* state, VALUE code) {
     v8::Unlocker unlocker;
     return rb_protect(&doUnlockCall, code, state);
   }

   VALUE Locker::doUnlockCall(VALUE code) {
     return rb_funcall(code, rb_intern("call"), 0);
   }
}
