# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Tickettype < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Select
  private

  def position(...)
    attribute = ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'type',
    )

    attribute.position
  end

  def options(object_attribte)
    object_attribte.system_field_options.to_h { |entry| [entry['value'], entry['name']] }
  end
end
