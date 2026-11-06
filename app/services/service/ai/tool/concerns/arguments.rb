# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The arguments of a tool: the JSON schema the model or the MCP client gets, and what is wrong with the arguments of a
#   call before the tool runs.
module Service::AI::Tool::Concerns::Arguments
  extend ActiveSupport::Concern

  module ClassMethods
    # @param surface [Symbol] :harness or :mcp, whose defaults and descriptions the schema shows
    def input_schema(surface: :harness)
      properties = tool_parameters.transform_values do |spec|
        {
          type:        spec[:type].to_s,
          description: parameter_description(spec, surface),
          **spec.slice(:enum, :items),
          default:     parameter_default(spec, surface),
          **spec.slice(:minimum, :maximum),
        }.compact
      end

      required = tool_parameters.select { |_name, spec| spec[:required] }.keys

      { type: 'object', properties:, required:, additionalProperties: false }
    end

    # @param arguments [Hash] with string keys
    # @param surface [Symbol] where the call comes from: :harness or :mcp
    # @return [Array<String>] what is wrong with the arguments, empty when they fit
    def argument_errors(arguments, surface: :harness)
      missing = tool_parameters.select { |name, spec| spec[:required] && arguments[name].nil? }.keys
      unknown = arguments.keys - tool_parameters.keys
      errors  = missing.map { |name| "missing required argument '#{name}'" } +
                unknown.map { |name| "unknown argument '#{name}'" } +
                arguments.slice(*tool_parameters.keys).filter_map { |name, value| value_error(name, value) }

      errors.presence || naming_errors(arguments, surface)
    end

    def parameter_default(spec, surface)
      (spec[:mcp_default] if surface == :mcp) || spec[:default]
    end

    private

    def parameter_description(spec, surface)
      (spec[:mcp_description] if surface == :mcp) || spec[:description]
    end

    # How the caller named the object; over MCP it has to, as there is no conversation that could, and so it has to for
    #   an object that is no starting object.
    def naming_errors(arguments, surface)
      locator = tool_loads&.dig(:locator)
      return [] if locator.nil?
      return [locator::NO_NAME] if (surface == :mcp || !tool_loads[:starting]) && !locator.named?(arguments) && !tool_loads[:optional]

      locator.argument_errors(arguments)
    end

    def value_error(name, value)
      return if value.nil?

      spec = tool_parameters[name]
      return "argument '#{name}' must be of type #{spec[:type]}" if !Service::AI::Tool::TYPES.fetch(spec[:type]).call(value)

      item_error = spec[:items] && item_error(name, value, spec[:items])
      return item_error if item_error

      return "argument '#{name}' must be at least #{spec[:minimum]}" if spec[:minimum] && value < spec[:minimum]
      return "argument '#{name}' must be at most #{spec[:maximum]}" if spec[:maximum] && value > spec[:maximum]

      "argument '#{name}' must be one of #{enum_text(spec[:enum])}" if spec[:enum]&.exclude?(value)
    end

    def enum_text(values)
      values.map { |allowed| allowed.is_a?(String) ? allowed : allowed.to_json }.join(', ')
    end

    def item_error(name, value, items)
      item_type = items.with_indifferent_access[:type].to_sym
      return if value.all? { |item| Service::AI::Tool::TYPES.fetch(item_type).call(item) }

      "argument '#{name}' must contain only values of type #{item_type}"
    end
  end
end
