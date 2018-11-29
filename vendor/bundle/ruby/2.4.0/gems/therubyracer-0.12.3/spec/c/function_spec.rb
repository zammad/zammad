require 'spec_helper'

describe V8::C::Function do
  requires_v8_context

  it "can be called" do
    fn = run '(function() {return "foo"})'
    fn.Call(@cxt.Global(), []).Utf8Value().should eql "foo"
  end

  it "can be called with arguments and context" do
    fn = run '(function(one, two, three) {this.one = one; this.two = two; this.three = three})'
    one = V8::C::Object::New()
    two = V8::C::Object::New()
    fn.Call(@cxt.Global(), [one, two, 3])
    @cxt.Global().Get("one").should eql one
    @cxt.Global().Get("two").should eql two
    @cxt.Global().Get("three").should eql 3
  end

  it "can be called as a constructor" do
    fn = run '(function() {this.foo = "foo"})'
    fn.NewInstance().Get(V8::C::String::New('foo')).Utf8Value().should eql "foo"
  end

  it "can be called as a constructor with arguments" do
    fn = run '(function(foo) {this.foo = foo})'
    object = fn.NewInstance([V8::C::String::New("bar")])
    object.Get(V8::C::String::New('foo')).Utf8Value().should eql "bar"
  end

  it "doesn't kill the world if invoking it throws a javascript exception" do
    V8::C::TryCatch() do
      fn = run '(function() { throw new Error("boom!")})'
      fn.Call(@cxt.Global(), [])
      fn.NewInstance([])
    end
  end


  def run(source)
    source = V8::C::String::New(source.to_s)
    filename = V8::C::String::New("<eval>")
    script = V8::C::Script::New(source, filename)
    result = script.Run()
    result.kind_of?(V8::C::String) ? result.Utf8Value() : result
  end
end
