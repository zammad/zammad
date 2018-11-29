require 'spec_helper'

describe V8::C::Exception do
  requires_v8_context

  it "can be thrown from Ruby" do
    t = V8::C::FunctionTemplate::New(method(:explode))
    @cxt.Global().Set("explode", t.GetFunction())
    script = V8::C::Script::New(<<-JS, '<eval>')
    (function() {
      try {
        explode()
      } catch (e) {
        return e.message
      }
    })()
    JS
    result = script.Run()
    result.should_not be_nil
    result.should be_kind_of(V8::C::String)
    result.Utf8Value().should eql 'did not pay syntax'
  end

  def explode(arguments)
    error = V8::C::Exception::SyntaxError('did not pay syntax')
    V8::C::ThrowException(error)
  end
end
