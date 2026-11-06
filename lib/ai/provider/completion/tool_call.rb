# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A call of a tool that the model asked for: part of a result of AI::Provider#complete, and of the assistant message
# that carries it back in the next call.
#
# It accepts whatever arguments the model wrote. Arguments that are no JSON object make the call invalid instead of
# failing the whole reply, so that the model can be answered with an error result and try again.
class AI::Provider::Completion::ToolCall
  attr_reader :id, :name, :arguments, :raw_arguments

  # @param id [String] the id of the call, which its result refers to
  # @param name [String] the name of the tool to call
  # @param arguments [Hash, String, nil] an object, or the JSON text the model wrote; blank means none
  # @raise [ArgumentError] for a missing id
  def initialize(id:, name:, arguments:)
    raise ArgumentError, 'tool call requires an id' if !id.is_a?(String) || id.blank?

    @id   = id
    @name = name

    @arguments, @raw_arguments = parse(arguments)
  end

  # True when the arguments are no JSON object: there is nothing to run the tool with. They are kept as the model
  # sent them in #raw_arguments.
  def invalid?
    arguments.nil?
  end

  def to_h
    { id:, name:, arguments:, raw_arguments: }.compact
  end

  private

  def parse(arguments)
    return [arguments, nil] if arguments.is_a?(Hash)
    return [{}, nil] if arguments.nil? || (arguments.is_a?(String) && arguments.blank?)
    return [nil, arguments.to_json] if !arguments.is_a?(String)

    parsed = JSON.parse(arguments)
    parsed.is_a?(Hash) ? [parsed, nil] : [nil, arguments]
  rescue JSON::ParserError
    [nil, arguments]
  end
end
