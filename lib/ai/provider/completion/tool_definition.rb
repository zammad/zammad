# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A tool the model may call in a conversation sent with AI::Provider#complete.
class AI::Provider::Completion::ToolDefinition
  # The names every provider accepts (OpenAI and Anthropic allow nothing else).
  NAME_FORMAT = %r{\A[a-zA-Z0-9_-]{1,64}\z}

  attr_reader :name, :description, :input_schema

  # @param name [String] letters, digits, '_' and '-', at most 64 characters
  # @param description [String] what the tool does and when to call it
  # @param input_schema [Hash] a JSON Schema of type object for its arguments
  # @raise [ArgumentError] for a name, description or schema the providers would reject
  def initialize(name:, description:, input_schema:)
    @name         = name
    @description  = description
    @input_schema = input_schema

    validate!
  end

  def to_h
    { name:, description:, input_schema: }
  end

  private

  def validate!
    raise ArgumentError, "invalid tool name: #{name.inspect}" if !name.is_a?(String) || !name.match?(NAME_FORMAT)
    raise ArgumentError, "tool #{name} requires a description" if !description.is_a?(String) || description.blank?
    raise ArgumentError, "tool #{name} requires an input schema of type object" if !object_schema?
  end

  def object_schema?
    input_schema.is_a?(Hash) && input_schema.with_indifferent_access[:type] == 'object'
  end
end
