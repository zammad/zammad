module Mixin
  # This modules enables to redirect all calls to methods that are
  # not defined to the declared instance variable. This comes handy
  # when you wan't extend a Ruby core class like Hash.
  # To inherit directly from such classes is a bad idea and should be avoided.
  # This way allows it indirectly.
  module InstanceWrapper
    module ClassMethods
      # Creates the class macro `wrap` that activates
      # the wrapping for the given instance variable name.
      #
      # @param [Symbol] variable the name of the instance variable to wrap around
      #
      # @example
      #  wrap :@some_hash
      #
      # @return [nil]
      def wrap(variable)
        define_method(:instance) {
          instance_variable_get(variable)
        }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    private

    def method_missing(method, *args, &block)
      if instance.respond_to?(method)
        instance.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_all)
      instance.respond_to?(method_sym, include_all)
    end
  end
end
