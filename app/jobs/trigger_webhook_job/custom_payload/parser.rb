# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::Parser
  # This module is used to scan, collect all replacment variables within a
  # custom payload, parse them for validity and replace, escape certain
  # characters in the final payload.

  private

  STRING_LIKE_CLASSES = %w[
    String
    ActiveSupport::TimeWithZone
    ActiveSupport::Duration
  ].freeze

  # This module validates the scanned replacement variables.
  def parse(variables, tracks)
    mappings = {}

    variables.each do |variable|
      methods = variable.split('.')
      object = methods.shift

      mappings[variable] = validate_object!(object, tracks)
      next if !mappings[variable].nil?

      reference = tracks[object.to_sym]
      mappings[variable] = validate_methods!(methods, reference, object)
    end

    mappings
  end

  # Replace, escape double quotes and whitespace characters to ensure the
  # payload is valid JSON.
  def replace(record, mappings)
    mappings.each do |variable, value|
      escaped_variable = Regexp.escape(variable)
      pattern = %r{("\#\{#{escaped_variable}\}"|\#\{#{escaped_variable}\})}

      is_string_like = value.class.to_s.in?(STRING_LIKE_CLASSES)

      record.gsub!(pattern) do |match|
        if match.start_with?('"')
          escaped_value = escape_replace_value(value, is_string_like:)
          is_string_like ? "\"#{escaped_value}\"" : escaped_value
        else
          escape_replace_value(value, is_string_like: true)
        end
      end
    end

    record
  end

  def escape_replace_value(value, is_string_like: false)
    if is_string_like
      value.to_s
        .gsub(%r{"}, '\"')
        .gsub(%r{\n}, '\n')
        .gsub(%r{\r}, '\r')
        .gsub(%r{\t}, '\t')
        .gsub(%r{\f}, '\f')
        .gsub(%r{\v}, '\v')
    else
      value.to_json
    end
  end

  # Scan the custom payload for replacement variables.
  def scan(record)
    placeholders = record.scan(%r{(#\{[a-z0-9_.?!]+\})}).flatten.uniq

    return [] if placeholders.blank?

    variables = []
    placeholders.each do |placeholder|
      next if !placeholder.match?(%r{^#\{(.+)\}$})

      placeholder.gsub!(%r{^#\{(.+)\}$}, '\1')
      variables.push(placeholder)
    end

    variables
  end
end
