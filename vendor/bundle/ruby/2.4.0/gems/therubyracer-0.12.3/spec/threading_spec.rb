require 'spec_helper'

describe "Timeouts" do
  it "allows for timeout on context" do
    ctx = V8::Context.new(:timeout => 10)
    lambda {ctx.eval("while(true){}")}.should(raise_error)

    # context should not be bust after it exploded once
    ctx["x"] = 1;
    ctx.eval("x=2;")
    ctx["x"].should == 2
  end
end

describe "using v8 from multiple threads", :threads => true do

  it "creates contexts from within threads" do
    10.times.collect do
      Thread.new do
        V8::Context.new
      end
    end.each {|t| t.join}
    V8::Context.new
  end

  it "executes codes on multiple threads simultaneously" do
    5.times.collect{V8::Context.new}.collect do |ctx|
      Thread.new do
        ctx['x'] = 99
        while ctx['x'] > 0
          ctx.eval 'for (i=10000;i;i--){};--x'
        end
      end
    end.each {|t| t.join}
  end

  it "can access the current thread id" do
    V8::C::Locker() do
      V8::C::V8::GetCurrentThreadId().should_not be_nil
    end
  end

  it "can pre-empt a running JavaScript thread" do
    pending "need to release the GIL while executing V8 code"
    begin
      V8::C::Locker::StartPreemption(2)
      thread_id = nil
      Thread.new do
        loop until thread_id
        puts "thread id: #{thread_id}"
        V8::C::V8::TerminateExecution(thread_id)
      end
      Thread.new do
        V8::C::Locker() do
          thread_id = V8::C::V8::GetCurrentThreadId()
          V8::Context.new {|cxt| cxt.eval('while (true) {}')}
        end
      end
      V8::C::V8::TerminateExecution(thread_id)
    ensure
      V8::C::Locker::StopPreemption()
    end
  end
end
