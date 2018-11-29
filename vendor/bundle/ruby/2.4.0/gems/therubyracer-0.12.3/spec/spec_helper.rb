require 'v8'

def run_v8_gc
  V8::C::V8::LowMemoryNotification()
  while !V8::C::V8::IdleNotification() do
  end
end

def rputs(msg)
  puts "<pre>#{ERB::Util.h(msg)}</pre>"
  $stdout.flush
end

module V8ContextHelpers
  module GroupMethods
    def requires_v8_context
      around(:each) do |example|
        bootstrap_v8_context(&example)
      end
    end
  end

  def bootstrap_v8_context
    V8::C::Locker() do
      V8::C::HandleScope() do
        @cxt = V8::C::Context::New()
        begin
          @cxt.Enter()
          yield
        ensure
          @cxt.Exit()
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include V8ContextHelpers
  c.extend V8ContextHelpers::GroupMethods
  c.expect_with(:rspec) { |c| c.syntax = :should }
end
