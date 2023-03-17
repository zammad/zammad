# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::SubSequence::Mixin::Base
  private

  def sequence
    raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
  end

  def sequence_name
    @sequence_name ||= sequence
  end

  def default_params
    {}
  end

  def default_parameter
    @default_parameter ||= default_params
  end

  def sequence_resource(resource = nil, &)
    parameters = sanitized_sequence_parameters!(resource, &)
    return if parameters.blank?

    ::Sequencer.process(sequence_name,
                        parameters: parameters)
  end

  def sanitized_sequence_parameters!(resource, &)
    parameters = sequence_parameters(resource, &)

    if parameters.nil?
      logger.debug { "Skipping processing of Sub-Sequence '#{sequence_name}'. `sequence_resource` block returned `nil` in '#{self.class.name}'." }
      return
    end

    if parameters[:resource].blank?
      raise '`resource` parameter missing. It is required as an argument to `sequence_resource` or as `:resource` key value of the block result.'
    end

    parameters.tap do |result|
      result[:resource] = result[:resource].to_h.with_indifferent_access
    end
  end

  def sequence_parameters(resource)
    # creates a dup/copy of `default_parameter`
    parameters = default_parameter.merge(resource: resource)

    return parameters if !block_given?

    yield(parameters)
  end

  def sequence_resources(resources, &)
    resources.each do |resource|
      sequence_resource(resource, &)
    end
  end
end
