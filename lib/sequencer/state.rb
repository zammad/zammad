# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'mixin/rails_logger'
require_dependency 'mixin/start_finish_logger'

class Sequencer
  class State
    include ::Mixin::RailsLogger
    include ::Mixin::StartFinishLogger

    def initialize(sequence, parameters: {}, expecting: nil)
      @index        = -1
      @units        = sequence.units
      @result_index = @units.count
      @values       = {}

      initialize_attributes(sequence.units)
      initialize_parameters(parameters)
      initialize_expectations(expecting || sequence.expecting)
    end

    # Stores a value for the given attribute. Value can be a regular object
    # or the result of a given code block.
    # The attribute gets validated against the .provides list of attributes.
    # In the case than an attribute gets provided that is not declared to
    # be provided an exception will be raised.
    #
    # @param [Symbol] attribute the attribute for which the value gets provided.
    # @param [Object] value the value that should get stored for the given attribute.
    # @yield [] executes the given block and takes the result as the value.
    # @yieldreturn [Object] the value for the given attribute.
    #
    # @example
    #  state.provide(:sum, 3)
    #
    # @example
    #  state.provide(:sum) do
    #    some_value = rand(100)
    #    some_value * 3
    #  end
    #
    # @raise [RuntimeError] if the attribute is not provideable from the calling Unit
    #
    # @return [nil]
    def provide(attribute, value = nil)
      if provideable?(attribute)
        value = yield if block_given?
        set(attribute, value)
      else
        value = "UNEXECUTED BLOCK: #{caller(1..1).first}" if block_given?
        unprovideable_setter(attribute, value)
      end
    end

    # Returns the value of the given attribute.
    # The attribute gets validated against the .uses and .optionals
    # lists of attributes. In the case that an attribute gets used
    # that is not declared to be used or optional, an exception
    # gets raised.
    #
    # @param [Symbol] attribute the attribute for which the value is requested.
    #
    # @example
    #  state.use(:answer)
    #  #=> 42
    #
    # @raise [RuntimeError] if the attribute is not useable from the calling Unit
    #
    # @return [nil]
    def use(attribute)
      if useable?(attribute)
        get(attribute)
      else
        unaccessable_getter(attribute)
      end
    end

    # Returns the value of the given attribute.
    # The attribute DOES NOT get validated against the .uses list of attributes.
    # Use this method only in edge cases and prefer .optional macro and state.use otherwise.
    #
    # @param [Symbol] attribute the attribute for which the value is requested.
    #
    # @example
    #  state.optional(:answer)
    #  #=> 42
    #
    # @example
    #  state.optional(:unknown)
    #  #=> nil
    #
    # @return [Object, nil]
    def optional(attribute)
      return get(attribute) if @attributes.known?(attribute)

      logger.public_send(log_level[:optional]) { "Access to unknown optional attribute '#{attribute}'." }
      nil
    end

    # Checks if a value for the given attribute is provided.
    # The attribute DOES NOT get validated against the .uses list of attributes.
    # Use this method only in edge cases and prefer .optional macro and state.use otherwise.
    #
    # @param [Symbol] attribute the attribute which should get checked.
    #
    # @example
    #  state.provided?(:answer)
    #  #=> true
    #
    # @example
    #  state.provided?(:unknown)
    #  #=> false
    #
    # @return [Boolean]
    def provided?(attribute)
      optional(attribute) != nil
    end

    # Unsets the value for the given attribute.
    # The attribute gets validated against the .uses list of attributes.
    # In the case than an attribute gets unset that is not declared
    # to be used an exception will be raised.
    #
    # @param [Symbol] attribute the attribute for which the value gets unset.
    #
    # @example
    #  state.unset(:answer)
    #
    # @raise [RuntimeError] if the attribute is not useable from the calling Unit
    #
    # @return [nil]
    def unset(attribute)
      value = nil
      if useable?(attribute)
        set(attribute, value)
      else
        unprovideable_setter(attribute, value)
      end
    end

    # Handles state processing of the next Unit in the Sequence while executing
    # the given block. After the Unit is processed the state will get cleaned up
    # and no longer needed attribute values will get discarded.
    #
    # @yield [] executes the given block and handles the state changes before and afterwards.
    #
    # @example
    #  state.process do
    #   unit.process
    #  end
    #
    # @return [nil]
    def process
      @index += 1
      yield
      cleanup
    end

    # Handles state processing of the next Unit in the Sequence while executing
    # the given block. After the Unit is processed the state will get cleaned up
    # and no longer needed attribute values will get discarded.
    #
    # @example
    #  state.to_h
    #  #=> {"ssl_verify"=>true, "host_url"=>"ldaps://192...", ...}
    #
    # @return [Hash{Symbol => Object}]
    def to_h
      available.map { |identifier| [identifier, @values[identifier]] }.to_h
    end

    private

    def available
      @attributes.select do |_identifier, attribute|
        @index.between?(attribute.from, attribute.till)
      end.keys
    end

    def unit(index = nil)
      @units[index || @index]
    end

    def provideable?(attribute)
      unit.provides.include?(attribute)
    end

    def useable?(attribute)
      return true if unit.uses.include?(attribute)

      unit.optional.include?(attribute)
    end

    def set(attribute, value)
      logger.public_send(log_level[:set]) { "Setting '#{attribute}' value (#{value.class.name}): #{value.inspect}" }
      @values[attribute] = value
    end

    def get(attribute)
      value = @values[attribute]
      logger.public_send(log_level[:get]) { "Getting '#{attribute}' value (#{value.class.name}): #{value.inspect}" }
      value
    end

    def unprovideable_setter(attribute, value)
      message = "Unprovideable attribute '#{attribute}' set with value (#{value.class.name}): #{value.inspect}"
      logger.error(message)
      raise message
    end

    def unaccessable_getter(attribute)
      message = "Unaccessable getter used for attribute '#{attribute}'"
      logger.error(message)
      raise message
    end

    def initialize_attributes(units)
      log_start_finish(log_level[:attribute_initialization][:start_finish], 'Attributes lifespan initialization') do
        @attributes = Sequencer::Units::Attributes.new(units.declarations)
        logger.public_send(log_level[:attribute_initialization][:attributes]) { "Attributes lifespan: #{@attributes.inspect}" }
      end
    end

    def initialize_parameters(parameters)
      logger.public_send(log_level[:parameter_initialization][:parameters]) { "Initializing Sequencer::State with initial parameters: #{parameters.inspect}" }

      log_start_finish(log_level[:parameter_initialization][:start_finish], 'Attribute value provisioning check and initialization') do

        @attributes.each do |identifier, attribute|

          if !attribute.will_be_used?
            logger.public_send(log_level[:parameter_initialization][:unused]) { "Attribute '#{identifier}' is provided by Unit(s) but never used." }
            next
          end

          init_param    = parameters.key?(identifier)
          provided_attr = attribute.will_be_provided?

          if !init_param && !provided_attr
            next if attribute.optional?

            message = "Attribute '#{identifier}' is used in Unit '#{unit(attribute.to).name}' (index: #{attribute.to}) but is not provided or given via initial parameters."
            logger.error(message)
            raise message
          end

          # skip if attribute is provided by an Unit but not
          # an initial parameter
          next if !init_param

          # update 'from' lifespan information for attribute
          # since it's provided via the initial parameter
          attribute.from = @index

          # set initial value
          set(identifier, parameters[identifier])
        end
      end
    end

    def initialize_expectations(expected_attributes)
      expected_attributes.each do |identifier|
        logger.public_send(log_level[:expectations_initialization]) { "Adding attribute '#{identifier}' to the list of expected result attributes." }
        @attributes[identifier].to = @result_index
      end
    end

    def cleanup
      log_start_finish(log_level[:cleanup][:start_finish], "State cleanup of Unit #{unit.name} (index: #{@index})") do

        @attributes.delete_if do |identifier, attribute|
          remove = !attribute.will_be_used?
          remove ||= attribute.till <= @index
          if remove && attribute.will_be_used?
            logger.public_send(log_level[:cleanup][:remove]) { "Removing unneeded attribute '#{identifier}': #{@values[identifier].inspect}" }
          end
          remove
        end
      end
    end

    def log_level
      @log_level ||= Sequencer.log_level_for(:state)
    end
  end
end
