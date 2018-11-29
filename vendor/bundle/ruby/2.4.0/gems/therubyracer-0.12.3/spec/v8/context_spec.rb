require 'spec_helper'

describe V8::Context do
  it "can be disposed of" do
    cxt = V8::Context.new
    cxt.enter do
      cxt['object'] = V8::Object.new
    end
    cxt.dispose()

    lambda {cxt.eval('1 + 1')}.should raise_error
    lambda {cxt['object']}.should raise_error
  end

  it "can be disposed of any number of times" do
    cxt = V8::Context.new
    10.times {cxt.dispose()}
  end
end
