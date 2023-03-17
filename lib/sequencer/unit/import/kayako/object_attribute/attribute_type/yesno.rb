# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Yesno < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  def local_value(value)
    value == 'yes'
  end

  private

  def data_type
    'boolean'
  end

  def data_type_specific_options
    {
      default: false,
      options: {
        true  => 'yes',
        false => 'no',
      },
    }
  end
end
