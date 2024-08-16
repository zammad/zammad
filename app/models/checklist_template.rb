# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplate < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include ChecklistTemplate::TriggersSubscriptions
  include ChecklistTemplate::Assets
  include CanChecklistSortedItems

  has_many :items, inverse_of: :checklist_template, dependent: :destroy

  validates :name, presence: { allow_blank: true }

  def create_from_template!(ticket_id:)
    raise ActiveRecord::RecordInvalid if !active

    new_checklist = Checklist.new(name:, ticket_id:)

    # Inherit only the text property from related checklist items.
    items.each do |item|
      new_checklist.items.build(text: item.text, initial_clone: true)
    end

    new_checklist.save!

    new_checklist
  end
end
