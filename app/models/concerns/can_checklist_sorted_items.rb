# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanChecklistSortedItems
  extend ActiveSupport::Concern

  #
  # BE AWARE: This is used for checklists and checklist templates
  #

  included do
    before_validation :default_sorted_item_ids

    def sorted_items
      items.in_order_of(:id, sorted_item_ids)
    end

    def default_sorted_item_ids
      self.sorted_item_ids ||= []
    end
  end
end
