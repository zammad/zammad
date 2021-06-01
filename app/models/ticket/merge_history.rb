# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::MergeHistory
  extend ActiveSupport::Concern

  included do
    after_destroy :merge_history_cleanup
  end

  private

  def merge_history_cleanup
    cleanup_type :received_merge, :id_from, :value_from
    cleanup_type :merged_into,    :id_to,   :value_to
  end

  def cleanup_type(history_type_name, lookup_attribute_name, target_attribute_name)
    type   = History.type_lookup   history_type_name
    object = History.object_lookup self.class.name

    History
      .where(history_object_id: object, history_type_id: type)
      .find_by(lookup_attribute_name =>  id)
      &.update!(target_attribute_name => replacement_title)
  end

  def replacement_title
    "##{number} #{title}"
  end
end
