require 'spec_helper'

describe "setting up handles scopes" do
  around(:each) do |example|
    V8::C::Locker() do
      cxt = V8::C::Context::New()
      begin
        cxt.Enter()
        example.run
      ensure
        cxt.Exit()
      end
    end
  end

  it "can allocate handle scopes" do
      V8::C::HandleScope() do
        V8::C::Object::New()
      end.class.should eql V8::C::Object
  end

  it "isn't the end of the world if a ruby exception is raised inside a HandleScope" do
    begin
      V8::C::HandleScope() do
        raise "boom!"
      end
    rescue StandardError => e
      e.message.should eql "boom!"
    end
  end
end
