require 'spec_helper'

describe V8::Function do
  it "uses the global context if it is invoked with nil as the context" do
    @cxt = V8::Context.new
    @cxt['foo'] = 'bar'
    @cxt.eval('(function() {return this.foo})').methodcall(nil).should eql 'bar'
  end
end
