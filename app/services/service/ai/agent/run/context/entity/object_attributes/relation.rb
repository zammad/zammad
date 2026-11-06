# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Relation < Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  RELATION_MAPPING = {
    'TicketState'    => 'Ticket::State',
    'TicketPriority' => 'Ticket::Priority',
  }.freeze

  def self.applicable?(object_attribute)
    object_attribute.data_option[:relation].present?
  end

  def prepare
    return if entity_value.blank?

    item = relation_type.find_by(id: entity_value)
    return if item.blank?

    {
      value: item.id,
      label: label(item),
    }
  end

  private

  # A record by the name it is stored under, as the instructions list it; a user, who has none, as the field layer
  #   names them.
  def label(item)
    item.respond_to?(:name) ? item.name : type.label(item.id)
  end

  def relation_type
    relation_name = RELATION_MAPPING[object_attribute.data_option[:relation]] || object_attribute.data_option[:relation]
    relation_name.constantize
  end
end
