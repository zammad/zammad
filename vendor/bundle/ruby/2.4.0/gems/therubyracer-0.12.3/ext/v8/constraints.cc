#include "rr.h"

namespace rr {
  void ResourceConstraints::Init() {
    ClassBuilder("ResourceConstraints").
      defineSingletonMethod("new", &initialize).
      defineMethod("max_young_space_size", &max_young_space_size).
      defineMethod("set_max_young_space_size", &set_max_young_space_size).
      defineMethod("max_old_space_size", &max_old_space_size).
      defineMethod("set_max_old_space_size", &set_max_old_space_size).
      defineMethod("max_executable_size", &set_max_executable_size).
      defineMethod("set_max_executable_size", &set_max_executable_size).
      store(&Class);
    ModuleBuilder("V8::C").
      defineSingletonMethod("SetResourceConstraints", &SetResourceConstraints);
  }

  VALUE ResourceConstraints::SetResourceConstraints(VALUE self, VALUE constraints) {
    Void(v8::SetResourceConstraints(ResourceConstraints(constraints)));
  }

  VALUE ResourceConstraints::initialize(VALUE self) {
    return ResourceConstraints(new v8::ResourceConstraints());
  }
  VALUE ResourceConstraints::max_young_space_size(VALUE self) {
    return INT2FIX(ResourceConstraints(self)->max_young_space_size());
  }
  VALUE ResourceConstraints::set_max_young_space_size(VALUE self, VALUE value) {
    Void(ResourceConstraints(self)->set_max_young_space_size(NUM2INT(value)));
  }
  VALUE ResourceConstraints::max_old_space_size(VALUE self) {
    return INT2FIX(ResourceConstraints(self)->max_old_space_size());
  }
  VALUE ResourceConstraints::set_max_old_space_size(VALUE self, VALUE value) {
    Void(ResourceConstraints(self)->set_max_old_space_size(NUM2INT(value)));
  }
  VALUE ResourceConstraints::max_executable_size(VALUE self) {
    return INT2FIX(ResourceConstraints(self)->max_executable_size());
  }
  VALUE ResourceConstraints::set_max_executable_size(VALUE self, VALUE value) {
    Void(ResourceConstraints(self)->set_max_executable_size(NUM2INT(value)));
  }

  // What do these even mean?
  // uint32_t* stack_limit() const { return stack_limit_; }
  // // Sets an address beyond which the VM's stack may not grow.
  // void set_stack_limit(uint32_t* value) { stack_limit_ = value; }

  template <> void Pointer<v8::ResourceConstraints>::unwrap(VALUE value) {
    Data_Get_Struct(value, class v8::ResourceConstraints, pointer);
  }
}