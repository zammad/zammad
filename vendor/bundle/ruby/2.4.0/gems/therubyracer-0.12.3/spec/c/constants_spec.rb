require 'spec_helper'

describe V8::C do
  requires_v8_context

  it "has constant methods for Undefined, Null, True and False" do
    [:Undefined, :Null, :True, :False].each do |name|
      constant = V8::C.send(name)
      constant.should_not be_nil
      V8::C.send(name).should be constant
    end
  end

  it "has a value for the Empty handle" do
    V8::C::Value::Empty.should_not be_nil
    V8::C::Value::Empty.should be V8::C::Value::Empty
  end

  it "can access the V8 version" do
    V8::C::V8::GetVersion().should match /^3\.16/
  end
end
