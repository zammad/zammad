# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Checkbox < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Select
  def local_value(value)
    multiple_values = value.split(',').map(&:to_i)

    relevant_options = attribute['options'].select { |option| multiple_values.include?(option['id']) }
    value_locales = relevant_options.filter_map { |option| option['values'].detect { |locale_item| locale_item['locale'] == default_language } }

    value_locales.pluck('translation')
  end

  private

  def data_type
    'multiselect'
  end
end
