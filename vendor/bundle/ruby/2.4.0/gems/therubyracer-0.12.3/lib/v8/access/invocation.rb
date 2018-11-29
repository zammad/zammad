class V8::Access
  module Invocation
    def methodcall(code, this, args)
      code.methodcall this, args
    end

    module Aritize
      def aritize(args)
        arity < 0 ? args : Array.new(arity).to_enum(:each_with_index).map {|item, i| args[i]}
      end
    end

    module Proc
      include Aritize
      def methodcall(this, args)
        call *aritize([this].concat(args))
      end
      ::Proc.send :include, self
    end

    module Method
      include Aritize
      def methodcall(this, args)
        context = V8::Context.current
        access = context.access
        if this.equal? self.receiver
          call *aritize(args)
        elsif this.class <= self.receiver.class
          access.methodcall(unbind, this, args)
        elsif this.equal? context.scope
          call *aritize(args)
        else
          fail TypeError, "cannot invoke #{self} on #{this}"
        end
      end
      ::Method.send :include, self
    end

    module UnboundMethod
      def methodcall(this, args)
        access = V8::Context.current.access
        access.methodcall bind(this), this, args
      end
      ::UnboundMethod.send :include, self
    end
  end
end
