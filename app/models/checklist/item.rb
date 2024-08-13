# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::Item < ApplicationModel
  include ChecksClientNotification
  include HasHistory
  include HasDefaultModelUserRelations
  include Checklist::TriggersSubscriptions
  include Checklist::Item::Assets

  belongs_to :checklist

  scope :for_user, ->(user) { joins(checklist: :ticket).where(tickets: { group: user.group_ids_access('read') }) }

  after_create :update_checklist
  after_update :update_checklist
  after_destroy :update_checklist

  validates :text, presence: { allow_blank: true }

  def history_log_attributes
    {
      related_o_id:           checklist.ticket_id,
      related_history_object: 'Ticket',
    }
  end

  def history_create
    history_log('created', created_by_id, { value_to: text })
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

  private

  def update_checklist
    if persisted?
      checklist.sorted_item_ids |= [id.to_s]
    else
      checklist.sorted_item_ids -= [id.to_s]
    end
    checklist.updated_at    = Time.zone.now
    checklist.updated_by_id = UserInfo.current_user_id || updated_by_id
    checklist.save!
  end
end
