# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One option of a list, or several: given by the option's label or its key, stored by its key.
class Service::EntityAttribute::Type::Select < Service::EntityAttribute::Type
  handles 'select', 'multiselect'

  def label(value)
    value.is_a?(Array) ? value.map { |item| labels.fetch(item, item) } : labels.fetch(value, value)
  end

  def settable?
    true
  end

  def value_schema
    return { type: 'array', items: { type: 'string' } } if multiple?

    { type: 'string' }
  end

  # Options kept as a hash are listed by their labels, as the form shows them; a list keeps the admin's order.
  def choices(allowed: nil)
    pairs = Option.flatten(option_list(allowed:)).reject(&:disabled).map { |option| [option.value, choice_label(option)] }

    options[:options].is_a?(Array) ? pairs : pairs.sort_by { |_value, label| label.downcase }
  end

  def option_list(allowed: nil)
    return hash_option_list(options[:options], allowed) if !options[:options].is_a?(Array)

    tree_options(options[:options], allowed)
  end

  private

  def convert(value, allowed:)
    return Array(value).map { |item| option_key(item, allowed) } if multiple?

    option_key(value, allowed)
  end

  def empty_value
    multiple? ? [] : nil
  end

  def multiple?
    attribute.data_type.start_with?('multi')
  end

  def option_key(value, allowed)
    invalid(:texts) if !value.is_a?(String)

    Service::EntityAttribute::NameMatch.match(normalize(value), choices(allowed:), filter: name, kind: 'option', label: :last.to_proc, short: ->(pair) { short_name(pair) }).first
  end

  def normalize(value)
    value.squish
  end

  # @param pair [Array(String, String)] an option's key and label
  def short_name(pair)
    pair.first
  end

  def choice_label(option)
    option.label
  end

  # An option Core Workflow does not allow is none, nor one the admin disabled where Core Workflow is not asked; it stays
  #   as the parent of those that are. Core Workflow allows a disabled option the record holds.
  def tree_options(items, allowed)
    items.filter_map do |item|
      item     = item.with_indifferent_access
      children = tree_options(Array(item[:children]), allowed)
      listed   = allowed.nil? ? !item[:disabled] : allowed.include?(item[:value])
      next if children.empty? && !listed

      Option.new(value: item[:value], label: item[:name], disabled: !listed, children:)
    end
  end

  # Removed options too, so that a value stored before still reads as its label.
  def labels
    @labels ||= ObjectManager::Attribute.data_options_hash(options[:historical_options] || {})
      .merge(ObjectManager::Attribute.data_options_hash(options[:options]))
  end
end
