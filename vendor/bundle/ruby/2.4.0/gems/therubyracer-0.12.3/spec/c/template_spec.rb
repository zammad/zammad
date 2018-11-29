require 'spec_helper'

describe V8::C::Template do
  requires_v8_context

  describe V8::C::FunctionTemplate do
    it "can be created with no arguments" do
      t = V8::C::FunctionTemplate::New()
      t.GetFunction().Call(@cxt.Global(),[]).StrictEquals(@cxt.Global()).should be_truthy
    end

    it "can be created with a callback" do
      receiver = V8::C::Object::New()
      f = nil
      callback = lambda do |arguments|
        arguments.Length().should be(2)
        arguments[0].Utf8Value().should eql 'one'
        arguments[1].Utf8Value().should eql 'two'
        arguments.Callee().StrictEquals(f).should be_truthy
        arguments.This().StrictEquals(receiver).should be_truthy
        arguments.Holder().StrictEquals(receiver).should be_truthy
        arguments.IsConstructCall().should be_falsey
        arguments.Data().Value().should be(42)
        V8::C::String::New("result")
      end
      t = V8::C::FunctionTemplate::New(callback, V8::C::External::New(42))
      f = t.GetFunction()
      f.Call(receiver, [V8::C::String::New('one'), V8::C::String::New('two')]).Utf8Value().should eql "result"
    end
  end
end
