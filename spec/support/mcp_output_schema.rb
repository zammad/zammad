# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'json_schemer'

# Checks the hash a tool returns over MCP against its output schema, closed: a field the schema does not declare fails
#   too, so that a tool cannot return more than its contract says. The published schema stays open, so that a client
#   that holds the old one during the cache time of the tool list does not refuse a new field.
module MCPOutputSchemaHelper
  # @return [Array<String>] the errors, empty when the value fits
  def output_schema_errors(schema, value)
    JSONSchemer.schema(closed_schema(schema.deep_stringify_keys)).validate(value.as_json).pluck('error')
  end

  def closed_schema(schema)
    case schema
    when Hash
      closed = schema.transform_values { |child| closed_schema(child) }
      closed['additionalProperties'] = false if closed.key?('properties') && !closed.key?('additionalProperties')
      closed
    when Array
      schema.map { |child| closed_schema(child) }
    else
      schema
    end
  end
end

RSpec.configure do |config|
  config.include MCPOutputSchemaHelper
end
