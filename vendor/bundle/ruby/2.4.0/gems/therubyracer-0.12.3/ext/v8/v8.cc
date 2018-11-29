#include "rr.h"

namespace rr {

void V8::Init() {
  ClassBuilder("V8").
    defineSingletonMethod("IdleNotification", &IdleNotification).
    defineSingletonMethod("SetFlagsFromString", &SetFlagsFromString).
    defineSingletonMethod("SetFlagsFromCommandLine", &SetFlagsFromCommandLine).
    defineSingletonMethod("PauseProfiler", &PauseProfiler).
    defineSingletonMethod("ResumeProfiler", &ResumeProfiler).
    defineSingletonMethod("IsProfilerPaused", &IsProfilerPaused).
    defineSingletonMethod("GetCurrentThreadId", &GetCurrentThreadId).
    defineSingletonMethod("TerminateExecution", &TerminateExecution).
    defineSingletonMethod("IsExecutionTerminating", &IsExecutionTerminating).
    defineSingletonMethod("Dispose", &Dispose).
    defineSingletonMethod("LowMemoryNotification", &LowMemoryNotification).
    defineSingletonMethod("AdjustAmountOfExternalAllocatedMemory", &AdjustAmountOfExternalAllocatedMemory).
    defineSingletonMethod("ContextDisposedNotification", &ContextDisposedNotification).
    defineSingletonMethod("SetCaptureStackTraceForUncaughtExceptions", &SetCaptureStackTraceForUncaughtExceptions).
    defineSingletonMethod("GetHeapStatistics", &GetHeapStatistics).
    defineSingletonMethod("GetVersion", &GetVersion);
}

VALUE V8::IdleNotification(int argc, VALUE argv[], VALUE self) {
  VALUE hint;
  rb_scan_args(argc, argv, "01", &hint);
  if (RTEST(hint)) {
    return Bool(v8::V8::IdleNotification(NUM2INT(hint)));
  } else {
    return Bool(v8::V8::IdleNotification());
  }
}
VALUE V8::SetFlagsFromString(VALUE self, VALUE string) {
  Void(v8::V8::SetFlagsFromString(RSTRING_PTR(string), (int)RSTRING_LEN(string)));
}
VALUE V8::SetFlagsFromCommandLine(VALUE self, VALUE args, VALUE remove_flags) {
  int argc = RARRAY_LENINT(args);
  char* argv[argc];
  for(int i = 0; i < argc; i++) {
    argv[i] = RSTRING_PTR(rb_ary_entry(args, i));
  }
  Void(v8::V8::SetFlagsFromCommandLine(&argc, argv, Bool(remove_flags)));
}
VALUE V8::AdjustAmountOfExternalAllocatedMemory(VALUE self, VALUE change_in_bytes) {
  return SIZET2NUM(v8::V8::AdjustAmountOfExternalAllocatedMemory(NUM2SIZET(change_in_bytes)));
}
VALUE V8::PauseProfiler(VALUE self) {
  Void(v8::V8::PauseProfiler());
}
VALUE V8::ResumeProfiler(VALUE self) {
  Void(v8::V8::ResumeProfiler());
}
VALUE V8::IsProfilerPaused(VALUE self) {
  return Bool(v8::V8::IsProfilerPaused());
}
VALUE V8::GetCurrentThreadId(VALUE self) {
  return INT2FIX(v8::V8::GetCurrentThreadId());
}
VALUE V8::TerminateExecution(VALUE self, VALUE thread_id) {
  Void(v8::V8::TerminateExecution(NUM2INT(thread_id)));
}
VALUE V8::IsExecutionTerminating(VALUE self) {
  return Bool(v8::V8::IsExecutionTerminating());
}
VALUE V8::Dispose(VALUE self) {
  Void(v8::V8::Dispose());
}
VALUE V8::LowMemoryNotification(VALUE self) {
  Void(v8::V8::LowMemoryNotification());
}
VALUE V8::ContextDisposedNotification(VALUE self) {
  return INT2FIX(v8::V8::ContextDisposedNotification());
}
VALUE V8::SetCaptureStackTraceForUncaughtExceptions(int argc, VALUE argv[], VALUE self) {
  VALUE should_capture; VALUE frame_limit; VALUE options;
  rb_scan_args(argc, argv, "12", &should_capture, &frame_limit, &options);
  int limit = RTEST(frame_limit) ? NUM2INT(frame_limit) : 10;
  Void(v8::V8::SetCaptureStackTraceForUncaughtExceptions(Bool(should_capture), limit, Stack::Trace::StackTraceOptions(options)));
}
VALUE V8::GetHeapStatistics(VALUE self, VALUE statistics_ptr) {
  Void(v8::V8::GetHeapStatistics(HeapStatistics(statistics_ptr)));
}
VALUE V8::GetVersion(VALUE self) {
  return rb_str_new2(v8::V8::GetVersion());
}
}