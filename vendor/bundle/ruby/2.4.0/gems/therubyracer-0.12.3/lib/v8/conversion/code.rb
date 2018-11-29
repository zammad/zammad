class V8::Conversion
  module Code
    include V8::Weak::Cell

    def to_v8
      fn = to_template.GetFunction()
      V8::Context.link self, fn
      return fn
    end

    def to_template
      weakcell(:template) {V8::C::FunctionTemplate::New(InvocationHandler.new(self))}
    end

    class InvocationHandler
      include V8::Error::Protect

      def initialize(code)
        @code = code
      end

      def call(arguments)
        protect do
          context = V8::Context.current
          access = context.access
          args = ::Array.new(arguments.Length())
          0.upto(args.length - 1) do |i|
            if i < args.length
              args[i] = context.to_ruby arguments[i]
            end
          end
          this = context.to_ruby arguments.This()
          context.to_v8 access.methodcall(@code, this, args)
        end
      end
    end
  end
end