# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'mixin/rails_logger'

class Sequencer
  class Unit
    class Base
      include ::Mixin::RailsLogger

      attr_reader :state

      # Creates the class macro `uses` that allows a Unit to
      # declare the attributes it will use via parameter or block.
      # On the other hand it returns the declared attributes if
      # called without parameters.
      #
      # This method can be called multiple times and will add the
      # given attributes to the list. It takes care of handling
      # duplicates so no uniq check is required. It's safe to use
      # for inheritance structures and modules.
      #
      # It additionally creates a getter instance method for each declared
      # attribute like e.g. attr_reader does. This allows direct access
      # to an attribute via `attribute_name`. See examples.
      #
      # @param [Array<Symbol>] attributes an optional list of attributes that the Unit uses
      #
      # @yield [] A block returning a list of attributes
      #
      # @example Via regular Array<Symbol> parameter
      #  uses :instance, :action, :connection
      #
      # @example Via block
      #  uses do
      #    additional = method(parameter)
      #    [:some, additional]
      #  end
      #
      # @example Listing declared attributes
      #  Unit::Name.uses
      #  # => [:instance, :action, :connection, :some, :suprise]
      #
      # @example Using declared attribute in the Unit via state object
      #  state.use(:instance).id
      #
      # @example Using declared attribute in the Unit via getter
      #  instance.id
      #
      # @return [Array<Symbol>] the list of all declared uses of a Unit.
      def self.uses(*attributes, &block)
        declaration_accessor(
          key:        __method__,
          attributes: attributes(*attributes, &block)
        ) do |attribute|
          use_getter(attribute)
        end
      end

      # Creates the class macro `optional` that allows a Unit to
      # declare the attributes it will use via parameter or block.
      # On the other hand it returns the declared attributes if
      # called without parameters.
      #
      # This method can be called multiple times and will add the
      # given attributes to the list. It takes care of handling
      # duplicates so no uniq check is required. It's safe to use
      # for inheritance structures and modules.
      #
      # It additionally creates a getter instance method for each declared
      # attribute like e.g. attr_reader does. This allows direct access
      # to an attribute via `attribute_name`. See examples.
      #
      # @param [Array<Symbol>] attributes an optional list of attributes that the Unit optional
      #
      # @yield [] A block returning a list of attributes
      #
      # @example Via regular Array<Symbol> parameter
      #  optional :instance, :action, :connection
      #
      # @example Via block
      #  optional do
      #    additional = method(parameter)
      #    [:some, additional]
      #  end
      #
      # @example Listing declared attributes
      #  Unit::Name.optional
      #  # => [:instance, :action, :connection, :some, :suprise]
      #
      # @example Using declared attribute in the Unit via state object
      #  state.use(:instance).id
      #
      # @example Using declared attribute in the Unit via getter
      #  instance.id
      #
      # @return [Array<Symbol>] the list of all declared optionals of a Unit.
      def self.optional(*attributes, &block)
        declaration_accessor(
          key:        __method__,
          attributes: attributes(*attributes, &block)
        ) do |attribute|
          use_getter(attribute)
        end
      end

      # Creates the class macro `provides` that allows a Unit to
      # declare the attributes it will provided via parameter or block.
      # On the other hand it returns the declared attributes if
      # called without parameters.
      #
      # This method can be called multiple times and will add the
      # given attributes to the list. It takes care of handling
      # duplicates so no uniq check is required. It's safe to use
      # for inheritance structures and modules.
      #
      # It additionally creates a setter instance method for each declared
      # attribute like e.g. attr_writer does. This allows direct access
      # to an attribute via `self.attribute_name = `. See examples.
      #
      # A Unit should usually not provide more than one or two attributes.
      # If your Unit provides it's doing to much and should be splitted
      # into multiple Units.
      #
      # @param [Array<Symbol>] attributes an optional list of attributes that the Unit provides
      #
      # @yield [] A block returning a list of attributes
      #
      # @example Via regular Array<Symbol> parameter
      #  provides :instance, :action, :connection
      #
      # @example Via block
      #  provides do
      #    additional = method(parameter)
      #    [:some, additional]
      #  end
      #
      # @example Listing declared attributes
      #  Unit::Name.provides
      #  # => [:instance, :action, :connection, :some, :suprise]
      #
      # @example Providing declared attribute in the Unit via state object parameter
      #  state.provide(:action, :created)
      #
      # @example Providing declared attribute in the Unit via state object block
      #  state.provide(:instance) do
      #    # ...
      #    instance
      #  end
      #
      # @example Providing declared attribute in the Unit via setter
      #  self.action = :created
      #
      # @return [Array<Symbol>] the list of all declared provides of a Unit.
      def self.provides(*attributes, &block)
        declaration_accessor(
          key:        __method__,
          attributes: attributes(*attributes, &block)
        ) do |attribute|
          provide_setter(attribute)
        end
      end

      def self.attributes(*attributes)
        # exectute block if given and add
        # the result to the (possibly empty)
        # list of given attributes
        attributes.concat(yield) if block_given?
        attributes
      end

      # This method is the heart of the #uses and #provides method.
      # It takes the declaration key and decides based on the given
      # parameters if the given attributes should get stored or
      # the stored values returned.
      def self.declaration_accessor(key:, attributes:)

        # if no attributes were given (storing)
        # return the already stored list of attributes
        return declarations(key).to_a if attributes.blank?

        # loop over all given attributes and
        # add them to the list of already stored
        # attributes for the given declaration key
        attributes.each do |attribute|
          next if !declarations(key).add?(attribute)

          # yield callback if given to create
          # getter or setter or whatever
          yield(attribute) if block_given?
        end
      end

      # This method creates the convenience method
      # getter for the given attribute.
      def self.use_getter(attribute)
        define_method(attribute) do
          instance_variable_cached(attribute) do
            state.use(attribute)
          end
        end
      end

      # This method creates the convenience method
      # setter for the given attribute.
      def self.provide_setter(attribute)
        define_method("#{attribute}=") do |value|
          state.provide(attribute, value)
        end
      end

      # This method is the attribute store for the given declaration key.
      def self.declarations(key)
        instance_variable_cached("#{key}_declarations") do
          declarations_initial(key)
        end
      end

      # This method initializes the attribute store for the given declaration key.
      # It checks if a parent class already has an existing store and duplicates it
      # for independent usage. Otherwise it creates a new one.
      def self.declarations_initial(key)
        return Set.new([]) if !superclass.respond_to?(:declarations)

        superclass.send(:declarations, key).dup
      end

      # This method creates an accessor to a cached instance variable for the given scope.
      # It will create a new variable with the result of the given block as an initial value.
      # On later calls it will return the already initialized, cached variable state.
      # The variable will be created by default as a class variable. If a instance scope is
      # passed it will create an instance variable instead.
      def self.instance_variable_cached(key, scope: self)
        cache = "@#{key}"
        value = scope.instance_variable_get(cache)
        return value if value

        value = yield
        scope.instance_variable_set(cache, value)
      end

      # This method is an instance wrapper around the class method .instance_variable_cached.
      # It will behave the same but passed the instance scope to create an
      # cached instance variable.
      def instance_variable_cached(key, &block)
        self.class.instance_variable_cached(key, scope: self, &block)
      end

      # This method is an convenience wrapper to create an instance
      # and then directly processing it.
      def self.process(*args)
        new(*args).process
      end

      def initialize(state)
        @state = state
      end

      def process
        raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
      end
    end
  end
end
