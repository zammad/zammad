require 'spec_helper'

describe V8::C::External do
  requires_v8_context

  it "can store and retrieve a value" do
    o = Object.new
    external = V8::C::External::New(o)
    external.Value().should be(o)
  end
end
