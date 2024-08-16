# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplate::Item < ApplicationModel
  include ChecksClientNotification
  include HasDefaultModelUserRelations
  include ChecklistTemplate::TriggersSubscriptions
  include ChecklistTemplate::Item::Assets

  belongs_to :checklist_template

  after_create :update_checklist
  after_destroy :update_checklist

  validates :text, presence: { allow_blank: true }
  validate :validate_item_count, on: :create

  private

  def update_checklist
    if persisted? && checklist_template.sorted_item_ids.exclude?(id.to_s)
      checklist_template.sorted_item_ids << id
    end
    if !persisted?
      checklist_template.sorted_item_ids = checklist_template.sorted_item_ids.reject { |sid| sid.to_s == id.to_s }
    end
    checklist_template.save!
  end

  def validate_item_count
    return if checklist_template.items.count < 100

    errors.add(:base, __('Checklist Template items are limited to 100 items per checklist.'))
  end
end
