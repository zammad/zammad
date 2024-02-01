# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SearchIndexAssociationsJob < SearchIndexJob

  def update_search_index(record)
    super

    updates = record.search_index_update_associations
    return true if updates.nil?
    return true if updates.all? { |update| update['total'].zero? }

    # reschedule job if there are more batches needed to update all objects
    self.class.set(wait: 1.second).perform_later(record.class.to_s, record.id)
  end
end
