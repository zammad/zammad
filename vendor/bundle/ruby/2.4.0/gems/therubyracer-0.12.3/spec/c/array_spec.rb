require 'spec_helper'

describe V8::C::Array do
  requires_v8_context

  it "can store and retrieve a value" do
    o = V8::C::Object::New()
    a = V8::C::Array::New()
    a.Length().should eql 0
    a.Set(0, o)
    a.Length().should eql 1
    a.Get(0).Equals(o).should be_truthy
  end

  it "can be initialized with a length" do
    a = V8::C::Array::New(5)
    a.Length().should eql 5
  end
end
