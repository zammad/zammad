# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A whole number, within the field's bounds.
class Service::EntityAttribute::Type::Number < Service::EntityAttribute::Type
  handles 'integer'

  def settable?
    true
  end

  def value_schema
    { type: 'integer', minimum: options[:min], maximum: options[:max] }.compact
  end

  private

  def convert(value, **)
    invalid(:integer) if !value.is_a?(::Integer)
    invalid(:minimum, minimum: options[:min]) if options[:min] && value < options[:min].to_i
    invalid(:maximum, maximum: options[:max]) if options[:max] && value > options[:max].to_i

    value
  end
end
