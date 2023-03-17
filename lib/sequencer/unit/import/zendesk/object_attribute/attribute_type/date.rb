# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Date < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base
  def init_callback(_object_attribte)
    @data_option.merge!(
      future: true,
      past:   true,
      diff:   0,
    )
  end
end
