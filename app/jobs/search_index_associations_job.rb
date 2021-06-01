# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexAssociationsJob < SearchIndexJob

  def update_search_index(record)
    super
    record.search_index_update_associations_delta
    record.search_index_update_associations_full
  end
end
