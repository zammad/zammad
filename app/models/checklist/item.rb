# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::Item < ApplicationModel
  include ChecksClientNotification
  include HasHistory
  include HasDefaultModelUserRelations
  include Checklist::Item::Assets
  include Checklist::Item::TriggersSubscriptions

  attr_accessor :initial_clone

  belongs_to :checklist
  belongs_to :ticket, optional: true

  scope :for_user, ->(user) { joins(checklist: :ticket).where(tickets: { group: user.group_ids_access('read') }) }

  before_validation :detect_ticket_reference, unless: :initial_clone
  before_validation :ensure_text_not_nil

  validate :detect_ticket_loop_reference, on: %i[create update], unless: -> { ticket.blank? || checklist.blank? }
  validate :validate_item_count, on: :create

  after_update :history_update_checked, if: -> { saved_change_to_checked? }
  after_destroy :update_checklist_on_destroy
  after_save :update_checklist_on_save

  history_attributes_ignored :checked

  def history_log_attributes
    {
      related_o_id:           checklist.ticket_id,
      related_history_object: 'Ticket',
    }
  end

  def history_create
    history_log('created', created_by_id, { value_to: text })
  end

  def history_update_checked
    history_log('checklist_item_checked', updated_by_id, {
                  value_from: text,
                  value_to:   checked.to_s,
                })
  end

  def history_destroy
    history_log('removed', updated_by_id, { value_to: text })
  end

  def notify_clients_data_attributes
    {
      id:            id,
      updated_at:    updated_at,
      updated_by_id: updated_by_id,
    }
  end

  def incomplete?
    return ticket_incomplete? if ticket.present?

    !checked
  end

  private

  def update_checklist_on_save
    checklist.sorted_item_ids |= [id.to_s]
    # It is necessary to make checklist dirty if checklist item was edited, but sorting was not changed
    # Otherwise legacy UI will not update properly
    checklist.updated_at = Time.current
    checklist.save!
  end

  def update_checklist_on_destroy
    # do not touch checklist if this item is destroyed by checklist's dependent: destroy
    return if destroyed_by_association

    checklist.sorted_item_ids -= [id.to_s]
    checklist.save!
  end

  def detect_ticket_reference
    return if changes.key?(:ticket_id)

    ticket = Ticket::Number.check(text)
    return if ticket.blank?

    self.ticket = ticket
  end

  def detect_ticket_loop_reference
    return if ticket.id != checklist.ticket.id

    errors.add(:ticket, __('reference must not be the checklist ticket.'))
  end

  def validate_item_count
    return if checklist.items.count < 100

    errors.add(:base, __('Checklist items are limited to 100 items per checklist.'))
  end

  def ticket_incomplete?
    # Consider the following ticket state types as incomplete:
    #   - closed
    #   - merged
    !ticket.state.state_type.name.match?(%r{^(closed|merged)$}i)
  end

  def ensure_text_not_nil
    self.text ||= ''
  end
end
