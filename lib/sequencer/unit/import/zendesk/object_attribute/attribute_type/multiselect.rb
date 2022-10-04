# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Multiselect < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Select
  def data_type(...)
    'multiselect'
  end
end
