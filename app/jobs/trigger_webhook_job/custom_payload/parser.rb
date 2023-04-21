# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::Parser
  # This module is used to scan, collect all replacment variables within a
  # custom payload, parse them for validity and replace, escape certain
  # characters in the final payload.

  private

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
      record.gsub!("\#{#{variable}}", value
      .to_s
      .gsub(%r{"}, '\"')
      .gsub(%r{\n}, '\n')
      .gsub(%r{\r}, '\r')
      .gsub(%r{\t}, '\t')
      .gsub(%r{\f}, '\f')
      .gsub(%r{\v}, '\v'))
    end

    record
  end

  # Scan the custom payload for replacement variables.
  def scan(record)
    placeholders = record.scan(%r{(#\{[a-z_.?!]+\})}).flatten.uniq

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
