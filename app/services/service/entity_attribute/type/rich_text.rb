# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Formatted text, stored as HTML and given as plain text either way.
class Service::EntityAttribute::Type::RichText < Service::EntityAttribute::Type
  handles 'richtext'

  def free_text?
    true
  end

  def plain(value)
    value.to_s.html2text
  end

  def settable?
    true
  end

  def value_schema
    { type: 'string' }
  end

  private

  def convert(value, **)
    invalid(:plain_text) if !value.is_a?(String)

    value.text2html
  end
end
