# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Checklists
  extend ActiveSupport::Concern

  included do
    has_many :referencing_checklist_items, class_name: 'Checklist::Item', dependent: :nullify
    has_many :referencing_checklists, class_name: 'Checklist', through: :referencing_checklist_items, source: :checklist
    has_one  :checklist, dependent: :destroy

    after_save :update_referenced_checklist_items

    association_attributes_ignored :referencing_checklist_items
  end

  def attributes_with_association_ids
    attributes = super

    return attributes if !Setting.get('checklist')

    attributes['checklist_id']              = checklist&.id
    attributes['checklist_incomplete']      = checklist&.incomplete
    attributes['checklist_total']           = checklist&.total

    attributes
  end

  private

  def update_referenced_checklist_items
    return if !saved_change_to_state_id?

    is_closed = Checklist.ticket_closed?(self)

    referencing_checklist_items
      .where(checked: !is_closed)
      .each { |elem| elem.update! checked: is_closed }
  end
end
