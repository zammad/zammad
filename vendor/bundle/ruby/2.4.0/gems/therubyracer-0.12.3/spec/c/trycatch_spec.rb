require 'spec_helper'

describe V8::C::External do
  requires_v8_context

  it "can catch javascript exceptions" do
    V8::C::V8::SetCaptureStackTraceForUncaughtExceptions(true, 99, V8::C::StackTrace::kDetailed)
    V8::C::TryCatch() do |trycatch|
      source = V8::C::String::New(<<-JS)
      function one() {
        two()
      }
      function two() {
        three()
      }
      function three() {
        boom()
      }
      function boom() {
        throw new Error('boom!')
      }
      eval('one()')
      JS
      filename = V8::C::String::New("<eval>")
      script = V8::C::Script::New(source, filename)
      result = script.Run()
      trycatch.HasCaught().should be_truthy
      trycatch.CanContinue().should be_truthy
      exception = trycatch.Exception()
      exception.should_not be_nil
      exception.IsNativeError().should be_truthy
      trycatch.StackTrace().Utf8Value().should match /boom.*three.*two.*one/m
      message = trycatch.Message();
      message.should_not be_nil
      message.Get().Utf8Value().should eql "Uncaught Error: boom!"
      message.GetSourceLine().Utf8Value().should eql "        throw new Error('boom!')"
      message.GetScriptResourceName().Utf8Value().should eql "<eval>"
      message.GetLineNumber().should eql 11
      stack = message.GetStackTrace()
      stack.should_not be_nil
      stack.GetFrameCount().should eql 6
      frame = stack.GetFrame(0)
      frame.GetLineNumber().should eql 11
      frame.GetColumn().should eql 15
      frame.GetScriptName().Utf8Value().should eql "<eval>"
      frame.GetScriptNameOrSourceURL().Utf8Value().should eql "<eval>"
      frame.IsEval().should be_falsey
      stack.GetFrame(4).IsEval().should be_truthy
      frame.IsConstructor().should be_falsey
    end
  end
end
