# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Yes or no.
class Service::EntityAttribute::Type::Boolean < Service::EntityAttribute::Type
  handles 'boolean'

  def settable?
    true
  end

  def value_schema
    { type: 'boolean' }
  end

  # Yes and no by the admin's labels, for a list that offers both; a caller that sets the field gives true or false.
  def option_list(allowed: nil)
    hash_option_list(options[:options] || {}, allowed)
  end

  # The admin's label for yes or no, where the field has one; the options keep their keys as given or as text.
  def label(value)
    labels = options[:options] || {}

    labels.fetch(value) { labels.fetch(value.to_s, value) }
  end

  private

  def convert(value, **)
    invalid(:boolean) if [true, false].exclude?(value)

    value
  end
end
