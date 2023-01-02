# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Regexp < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def init_callback(object_attribte)
    @data_option.merge!(
      type:      'text',
      maxlength: 255,
      regex:     object_attribte.regexp_for_validation,
    )
  end

  private

  def data_type(...)
    'input'
  end
end
