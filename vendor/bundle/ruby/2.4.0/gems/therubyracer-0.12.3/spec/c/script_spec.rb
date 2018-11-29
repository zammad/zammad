# encoding: UTF-8
require 'spec_helper'

describe V8::C::Script do
  requires_v8_context

  it "can run a script and return a polymorphic result" do
    source = V8::C::String::New("(new Array())")
    filename = V8::C::String::New("<eval>")
    script = V8::C::Script::New(source, filename)
    result = script.Run()
    result.should be_kind_of V8::C::Array
  end

  it "can accept precompiled script data" do
    source = "7 * 6"
    name = V8::C::String::New("<spec>")
    origin = V8::C::ScriptOrigin.new(name)
    data = V8::C::ScriptData::PreCompile(source, source.length)
    data.HasError().should be_falsey
    script = V8::C::Script::New(V8::C::String::New(source), origin, data)
    script.Run().should eql 42
  end

  it "can detect errors in the script data" do
    source = "^ = ;"
    data = V8::C::ScriptData::PreCompile(source, source.length)
    data.HasError().should be_truthy
  end
end
