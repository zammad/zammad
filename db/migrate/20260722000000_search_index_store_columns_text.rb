# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SearchIndexStoreColumnsText < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')
    return if !SearchIndexBackend.enabled?

    SearchIndexBackend::STORE_NAMES_PER_MODEL.each_key do |model|
      # skipped because of the potentially huge amount of rows
      next if model == AuditLog

      # not all store models are indexable (e.g. Sla, PostmasterFilter)
      next if !model.method_defined?(:search_index_update_backend)

      model.in_batches.each_record do |record|
        SearchIndexJob.perform_later(model.to_s, record.id)
      end
    end
  end
end
