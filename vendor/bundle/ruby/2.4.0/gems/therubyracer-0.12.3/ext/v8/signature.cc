#include "rr.h"

namespace rr {
  void Signature::Init() {
    ClassBuilder("Signature").
      defineMethod("New", &New).
      store(&Class);
  }

  VALUE Signature::New(int argc, VALUE args[], VALUE self) {
    VALUE receiver; VALUE argv;
    rb_scan_args(argc, args, "02", &receiver, &argv);
    FunctionTemplate recv(receiver);
    int length = RARRAY_LENINT(argv);
    FunctionTemplate::array<FunctionTemplate> types(argv);
    return Signature(v8::Signature::New(recv, length, types));
  }
}