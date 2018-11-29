#include "rr.h"

namespace rr {
  void Stack::Init() {
    ClassBuilder("StackTrace").
      defineSingletonMethod("kLineNumber", &Trace::kLineNumber).
      defineSingletonMethod("kColumnOffset", &Trace::kColumnOffset).
      defineSingletonMethod("kScriptName", &Trace::kScriptName).
      defineSingletonMethod("kFunctionName", &Trace::kFunctionName).
      defineSingletonMethod("kIsEval", &Trace::kIsEval).
      defineSingletonMethod("kIsConstructor", &Trace::kIsConstructor).
      defineSingletonMethod("kScriptNameOrSourceURL", &Trace::kScriptNameOrSourceURL).
      defineSingletonMethod("kOverview", &Trace::kOverview).
      defineSingletonMethod("kDetailed", &Trace::kDetailed).
      defineSingletonMethod("CurrentStackTrace", &Trace::CurrentStackTrace).
      defineMethod("GetFrame", &Trace::GetFrame).
      defineMethod("GetFrameCount", &Trace::GetFrameCount).
      defineMethod("AsArray", &Trace::AsArray).
      store(&Trace::Class);
    ClassBuilder("StackFrame").
      defineMethod("GetLineNumber", &Frame::GetLineNumber).
      defineMethod("GetColumn", &Frame::GetColumn).
      defineMethod("GetScriptName", &Frame::GetScriptName).
      defineMethod("GetScriptNameOrSourceURL", &Frame::GetScriptNameOrSourceURL).
      defineMethod("GetFunctionName", &Frame::GetFunctionName).
      defineMethod("IsEval", &Frame::IsEval).
      defineMethod("IsConstructor", &Frame::IsConstructor).
      store(&Frame::Class);
  }

  VALUE Stack::Trace::GetFrame(VALUE self, VALUE index) {
    return Frame(Trace(self)->GetFrame(NUM2UINT(index)));
  }

  VALUE Stack::Trace::GetFrameCount(VALUE self) {
    return INT2FIX(Trace(self)->GetFrameCount());
  }

  VALUE Stack::Trace::AsArray(VALUE self) {
    return Array(Trace(self)->AsArray());
  }

  VALUE Stack::Trace::CurrentStackTrace(int argc, VALUE argv[], VALUE self) {
    VALUE frame_limit; VALUE options;
    rb_scan_args(argc, argv, "11", &frame_limit, &options);
    return Trace(v8::StackTrace::CurrentStackTrace(NUM2INT(frame_limit), StackTraceOptions(options)));
  }

  VALUE Stack::Frame::GetLineNumber(VALUE self) {
    return INT2FIX(Frame(self)->GetLineNumber());
  }

  VALUE Stack::Frame::GetColumn(VALUE self) {
    return INT2FIX(Frame(self)->GetColumn());
  }

  VALUE Stack::Frame::GetScriptName(VALUE self) {
    return String(Frame(self)->GetScriptName());
  }

  VALUE Stack::Frame::GetScriptNameOrSourceURL(VALUE self) {
    return String(Frame(self)->GetScriptNameOrSourceURL());
  }

  VALUE Stack::Frame::GetFunctionName(VALUE self) {
    return String(Frame(self)->GetFunctionName());
  }

  VALUE Stack::Frame::IsEval(VALUE self) {
    return Bool(Frame(self)->IsEval());
  }

  VALUE Stack::Frame::IsConstructor(VALUE self) {
    return Bool(Frame(self)->IsConstructor());
  }
}