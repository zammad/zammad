require 'spec_helper'

describe V8::Object do
  before do
    @object = V8::Context.new.eval('({foo: "bar", baz: "bang", qux: "qux1"})')
  end

  it "can list all keys" do
    @object.keys.sort.should eql %w(baz foo qux)
  end

  it "can list all values" do
    @object.values.sort.should eql %w(bang bar qux1)
  end
end
