# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplate < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include ChecklistTemplate::TriggersSubscriptions
  include ChecklistTemplate::Assets
  include CanChecklistSortedItems

  has_many :items, inverse_of: :checklist_template, dependent: :destroy

  validates :name, length: { maximum: 250 }

  def replace_items!(new_items)
    if new_items.count > 100
      raise Exceptions::UnprocessableEntity, __('Checklist Template items are limited to 100 items per checklist.')
    end

    ActiveRecord::Base.transaction do
      items.destroy_all

      self.sorted_item_ids = new_items
        .compact_blank
        .map { |elem| items.create! text: elem.strip }
        .map(&:id)

      save!
    end
  end
end
