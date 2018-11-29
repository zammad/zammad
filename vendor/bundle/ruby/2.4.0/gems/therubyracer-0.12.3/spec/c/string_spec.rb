require 'spec_helper'

describe V8::C::String do
  requires_v8_context

  it "can hold Unicode values outside the Basic Multilingual Plane" do
    string = V8::C::String::New("\u{100000}")
    string.Utf8Value().should eql "\u{100000}"
  end

  it "can naturally translate ruby strings into v8 strings" do
    V8::C::String::Concat(V8::C::String::New("Hello "), "World").Utf8Value().should eql "Hello World"
  end

  it "can naturally translate ruby objects into v8 strings" do
    V8::C::String::Concat(V8::C::String::New("forty two is "), 42).Utf8Value().should eql "forty two is 42"
  end
end
