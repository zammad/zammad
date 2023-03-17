# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Integer < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def init_callback(_object_attribte)
    @data_option.merge!(
      min: 0,
      max: 999_999_999,
    )
  end

  private

  def data_type(...)
    'integer'
  end
end
