# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::Item < ApplicationModel
  include ChecksClientNotification
  include HasDefaultModelUserRelations
  include Checklist::TriggersSubscriptions
  include Checklist::Item::Assets

  belongs_to :checklist

  scope :for_user, ->(user) { joins(checklist: :ticket).where(tickets: { group: user.group_ids_access('read') }) }

  after_create :update_checklist
  after_destroy :update_checklist

  validates :text, presence: { allow_blank: true }

  def notify_clients_data_attributes
    {
      id:            id,
      updated_at:    updated_at,
      updated_by_id: updated_by_id,
    }
  end

  private

  def update_checklist
    if persisted? && checklist.sorted_item_ids.exclude?(id.to_s)
      checklist.sorted_item_ids << id
    end
    if !persisted?
      checklist.sorted_item_ids = checklist.sorted_item_ids.reject { |sid| sid.to_s == id.to_s }
    end
    checklist.save!
  end
end
