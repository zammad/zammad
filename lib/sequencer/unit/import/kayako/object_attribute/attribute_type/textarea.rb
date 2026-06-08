# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Textarea < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  private

  def data_type_specific_options
    {
      type:      'textarea',
      maxlength: 65_535,
    }
  end
end
