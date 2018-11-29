#include "rr.h"

namespace rr {

  void Message::Init() {
    ClassBuilder("Message").
      defineMethod("Get", &Get).
      defineMethod("GetSourceLine", &GetSourceLine).
      defineMethod("GetScriptResourceName", &GetScriptResourceName).
      defineMethod("GetScriptData", &GetScriptData).
      defineMethod("GetStackTrace", &GetStackTrace).
      defineMethod("GetLineNumber", &GetLineNumber).
      defineMethod("GetStartPosition", &GetStartPosition).
      defineMethod("GetEndPosition", &GetEndPosition).
      defineMethod("GetStartColumn", &GetEndColumn).
      defineSingletonMethod("kNoLineNumberInfo", &kNoLineNumberInfo).
      defineSingletonMethod("kNoColumnInfo", &kNoColumnInfo).
      store(&Class);
  }

  VALUE Message::Get(VALUE self) {
    return String(Message(self)->Get());
  }
  VALUE Message::GetSourceLine(VALUE self) {
    return String(Message(self)->GetSourceLine());
  }
  VALUE Message::GetScriptResourceName(VALUE self) {
    return Value(Message(self)->GetScriptResourceName());
  }
  VALUE Message::GetScriptData(VALUE self) {
    return Value(Message(self)->GetScriptData());
  }
  VALUE Message::GetStackTrace(VALUE self) {
    return Stack::Trace(Message(self)->GetStackTrace());
  }
  VALUE Message::GetLineNumber(VALUE self) {
    return INT2FIX(Message(self)->GetLineNumber());
  }
  VALUE Message::GetStartPosition(VALUE self) {
    return INT2FIX(Message(self)->GetStartPosition());
  }
  VALUE Message::GetEndPosition(VALUE self) {
    return INT2FIX(Message(self)->GetEndPosition());
  }
  VALUE Message::GetStartColumn(VALUE self) {
    return INT2FIX(Message(self)->GetStartColumn());
  }
  VALUE Message::GetEndColumn(VALUE self) {
    return INT2FIX(Message(self)->GetEndColumn());
  }
}