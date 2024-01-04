# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SearchIndexAssociationsJob < SearchIndexJob

  def update_search_index(record)
    super
    record.search_index_update_associations
  end
end
