# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Textarea < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def init_callback(_object_attribte)
    @data_option.merge!(
      type:      'textarea',
      maxlength: 255,
    )
  end

  private

  def data_type(...)
    'textarea'
  end
end
