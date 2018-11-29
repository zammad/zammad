require 'spec_helper'

describe V8::C::Object do
  requires_v8_context

  it "can store and retrieve a value" do
    o = V8::C::Object::New()
    key = V8::C::String::New("foo")
    value = V8::C::String::New("bar")
    o.Set(key, value)
    o.Get(key).Utf8Value().should eql "bar"
  end

  it "can retrieve all property names" do
    o = V8::C::Object::New()
    o.Set(V8::C::String::New("foo"), V8::C::String::New("bar"))
    o.Set(V8::C::String::New("baz"), V8::C::String::New("bang"))
    names = o.GetPropertyNames()
    names.Length().should eql 2
    names.Get(0).Utf8Value().should eql "foo"
    names.Get(1).Utf8Value().should eql "baz"
  end
  it "can set an accessor from ruby" do
    o = V8::C::Object::New()
    property = V8::C::String::New("statement")
    callback_data = V8::C::String::New("I am Legend")
    left = V8::C::String::New("Yo! ")
    getter = proc do |name, info|
      info.This().StrictEquals(o).should be_truthy
      info.Holder().StrictEquals(o).should be_truthy
      V8::C::String::Concat(left, info.Data())
    end
    setter = proc do |name, value, info|
      left = value
    end
    o.SetAccessor(property, getter, setter, callback_data)
    o.Get(property).Utf8Value().should eql "Yo! I am Legend"
    o.Set(property, V8::C::String::New("Bro! "))
    o.Get(property).Utf8Value().should eql "Bro! I am Legend"
  end
  it "always returns the same ruby object for the same V8 object" do
    one = V8::C::Object::New()
    two = V8::C::Object::New()
    one.Set("two", two)
    one.Get("two").should be two
  end
end
