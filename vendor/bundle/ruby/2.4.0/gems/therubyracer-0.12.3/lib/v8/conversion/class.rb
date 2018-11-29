class V8::Conversion
  module Class
    include V8::Conversion::Code

    def to_template
      weakcell(:constructor) do
        template = V8::C::FunctionTemplate::New(V8::Conversion::Constructor.new(self))
        prototype = template.InstanceTemplate()
        prototype.SetNamedPropertyHandler(V8::Conversion::Get, V8::Conversion::Set)
        prototype.SetIndexedPropertyHandler(V8::Conversion::IGet, V8::Conversion::ISet)
        if self != ::Object && superclass != ::Object && superclass != ::Class
          template.Inherit(superclass.to_template)
        end
        template
      end
    end
  end

  class Constructor
    include V8::Error::Protect

    def initialize(cls)
      @class = cls
    end

    def call(arguments)
      arguments.extend Args
      protect do
        if arguments.linkage_call?
          arguments.link
        else
          arguments.construct @class
        end
      end
      return arguments.This()
    end

    module Args
      def linkage_call?
        self.Length() == 1 && self[0].IsExternal()
      end

      def link
        external = self[0]
        This().SetHiddenValue("rr::implementation", external)
        context.link external.Value(), This()
      end

      def construct(cls)
        context.link cls.new(*to_args), This()
      end

      def context
        V8::Context.current
      end

      def to_args
        args = ::Array.new(Length())
        0.upto(args.length - 1) do |i|
          args[i] = self[i]
        end
        return args
      end
    end
  end

  module Accessor
    include V8::Error::Protect
    def intercept(info, key, &block)
      context = V8::Context.current
      access = context.access
      object = context.to_ruby(info.This())
      handles_property = true
      dontintercept = proc do
        handles_property = false
      end
      protect do
        result = block.call(context, access, object, context.to_ruby(key), dontintercept)
        handles_property ? context.to_v8(result) : V8::C::Value::Empty
      end
    end
  end

  class Get
    extend Accessor
    def self.call(property, info)
      intercept(info, property) do |context, access, object, key, dontintercept|
        access.get(object, key, &dontintercept)
      end
    end
  end

  class Set
    extend Accessor
    def self.call(property, value, info)
      intercept(info, property) do |context, access, object, key, dontintercept|
        access.set(object, key, context.to_ruby(value), &dontintercept)
      end
    end
  end

  class IGet
    extend Accessor
    def self.call(property, info)
      intercept(info, property) do |context, access, object, key, dontintercept|
        access.iget(object, key, &dontintercept)
      end
    end
  end

  class ISet
    extend Accessor
    def self.call(property, value, info)
      intercept(info, property) do |context, access, object, key, dontintercept|
        access.iset(object, key, context.to_ruby(value), &dontintercept)
      end
    end
  end
end