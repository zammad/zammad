# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Text < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def init_callback(_object_attribte)
    @data_option.merge!(
      type:      'text',
      maxlength: 255,
    )
  end

  private

  def data_type(...)
    'input'
  end
end
