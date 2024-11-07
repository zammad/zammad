# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket changes.
module Ticket::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :trigger_subscriptions
    after_update_commit :trigger_checklist_subscriptions
    after_update_commit :trigger_link_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::TicketUpdates.trigger(self, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(self) })

    return true if !saved_change_to_attribute?('group_id')

    TaskbarUpdateTriggerSubscriptionsJob.perform_later("#{self.class}-#{id}")
  end

  TRIGGER_CHECKLIST_UPDATE_ON = %w[title group_id].freeze

  def trigger_checklist_subscriptions
    return if !saved_changes.keys.intersect? TRIGGER_CHECKLIST_UPDATE_ON

    Checklist
      .where(id: referencing_checklists)
      .includes(:ticket)
      .each do |elem|
        Gql::Subscriptions::Ticket::ChecklistUpdates.trigger(
          elem,
          arguments: {
            ticket_id: Gql::ZammadSchema.id_from_object(elem.ticket),
          }
        )
      end
  end

  TRIGGER_LINK_UPDATE_ON = %w[title state_id].freeze

  def trigger_link_subscriptions
    return if !saved_changes.keys.intersect? TRIGGER_LINK_UPDATE_ON

    Gql::Subscriptions::LinkUpdates.trigger(
      nil,
      arguments: {
        object_id:   Gql::ZammadSchema.id_from_object(self),
        target_type: self.class.name
      }
    )

    links = Link.list(
      link_object:       self.class.name,
      link_object_value: id
    ).uniq

    links.each do |link|
      target = link['link_object'].constantize.find(link['link_object_value'])

      Gql::Subscriptions::LinkUpdates.trigger(
        nil,
        arguments: {
          object_id:   Gql::ZammadSchema.id_from_object(target),
          target_type: link['link_object']
        }
      )
    end
  end
end
