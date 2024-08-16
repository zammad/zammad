# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include HasHistory
  include Checklist::TriggersSubscriptions
  include Checklist::Assets
  include CanChecklistSortedItems

  belongs_to :ticket, optional: true
  has_many :items, inverse_of: :checklist, dependent: :destroy

  scope :for_user, ->(user) { joins(:ticket).where(ticket: { group: user.group_ids_access('read') }) }

  after_update :update_ticket
  after_destroy :update_ticket

  validates :name,      presence: { allow_blank: true }
  validates :ticket_id, presence: true, uniqueness: { allow_nil: true }

  history_attributes_ignored :sorted_item_ids

  def history_log_attributes
    {
      related_o_id:           ticket_id,
      related_history_object: 'Ticket',
    }
  end

  def history_create
    history_log('created', created_by_id, { value_to: name })
  end

  def history_destroy
    history_log('removed', updated_by_id, { value_to: name })
  end

  def notify_clients_data_attributes
    {
      id:            id,
      ticket_id:     ticket_id,
      updated_at:    updated_at,
      updated_by_id: updated_by_id,
    }
  end

  def completed?
    incomplete.zero?
  end

  def incomplete
    Auth::RequestCache.fetch_value("Checklist/#{id}/incomplete") do
      items.count(&:incomplete?)
    end
  end

  def update_ticket
    ticket.updated_at    = Time.zone.now
    ticket.updated_by_id = UserInfo.current_user_id || updated_by_id
    ticket.save!
  end
end
