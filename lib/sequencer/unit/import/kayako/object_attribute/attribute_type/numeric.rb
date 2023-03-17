# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Numeric < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  private

  def data_type
    'integer'
  end

  def data_type_specific_options
    {
      min: 0,
      max: 999_999_999,
    }
  end
end
