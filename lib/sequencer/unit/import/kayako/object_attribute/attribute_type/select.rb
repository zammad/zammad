# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Select < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  def local_value(value)
    option_value = attribute['options'].detect { |option| option['id'] == value.to_i }
    value_locale = option_value['values'].detect { |locale_item| locale_item['locale'] == default_language }

    value_locale['translation']
  end

  private

  def data_type
    'select'
  end

  def data_type_specific_options
    {
      default: '',
      options: options,
    }
  end

  def options
    result = {}
    attribute['options'].each do |item|
      locale_item = item['values'].detect { |value| value['locale'] == default_language }
      result[ locale_item['translation'] ] = locale_item['translation']
    end
    result
  end
end
