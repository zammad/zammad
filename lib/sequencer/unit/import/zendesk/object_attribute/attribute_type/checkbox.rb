# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Checkbox < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base
  def init_callback(_object_attribte)
    @data_option.merge!(
      default: false,
      options: {
        true  => 'yes',
        false => 'no',
      },
    )
  end

  private

  def data_type(...)
    'boolean'
  end
end
