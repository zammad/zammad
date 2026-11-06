# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A line or a paragraph of plain text.
class Service::EntityAttribute::Type::Text < Service::EntityAttribute::Type
  handles 'input', 'textarea'

  def free_text?
    true
  end

  def settable?
    true
  end

  def value_schema
    { type: 'string', maxLength: options[:maxlength] }.compact
  end

  private

  def convert(value, **)
    invalid(:text) if !value.is_a?(String)
    invalid(:too_long, length: value.length, maximum: options[:maxlength]) if options[:maxlength] && value.length > options[:maxlength].to_i

    value
  end
end
