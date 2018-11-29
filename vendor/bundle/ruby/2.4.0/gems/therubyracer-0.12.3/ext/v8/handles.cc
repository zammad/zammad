#include "rr.h"

namespace rr {

void Handles::Init() {
  VALUE v8 = rb_define_module("V8");
  VALUE c = rb_define_module_under(v8, "C");
  rb_define_singleton_method(c, "HandleScope", (VALUE (*)(...))&HandleScope, -1);
}

VALUE Handles::HandleScope(int argc, VALUE* argv, VALUE self) {
  if (!rb_block_given_p()) {
    return Qnil;
  }
  int state = 0;
  VALUE code;
  rb_scan_args(argc,argv,"00&", &code);
  VALUE result = SetupAndCall(&state, code);
  if (state != 0) {
    rb_jump_tag(state);
  }
  return result;
}

VALUE Handles::SetupAndCall(int* state, VALUE code) {
  v8::HandleScope scope;
  return rb_protect(&DoCall, code, state);
}

VALUE Handles::DoCall(VALUE code) {
  return rb_funcall(code, rb_intern("call"), 0);
}

}