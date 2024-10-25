# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Checklists
  extend ActiveSupport::Concern

  included do
    has_many :referencing_checklist_items, class_name: 'Checklist::Item', dependent: :nullify
    has_many :referencing_checklists, class_name: 'Checklist', through: :referencing_checklist_items, source: :checklist

    belongs_to :checklist, dependent: :destroy, optional: true

    after_save :update_referenced_checklist_items

    association_attributes_ignored :referencing_checklist_items

    validates :checklist_id, uniqueness: { allow_nil: true }

    validate :ensure_checklist_did_not_exist
  end

  private

  def update_referenced_checklist_items
    return if !saved_change_to_state_id?

    is_closed = Checklist.ticket_closed?(self)

    referencing_checklist_items
      .where(checked: !is_closed)
      .each { |elem| elem.update! checked: is_closed }
  end

  def ensure_checklist_did_not_exist
    return if !checklist_id_changed?
    # All is good if checklist did not exist before or will not exist afterwards
    return if !checklist_id || !checklist_id_was

    errors.add :base, __('This ticket already has a checklist.')
  end
end
