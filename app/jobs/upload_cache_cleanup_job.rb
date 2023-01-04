# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UploadCacheCleanupJob < ApplicationJob
  def perform
    taskbar_form_ids = Taskbar.with_form_id.filter_map(&:persisted_form_id)
    return if store_object_id.blank?

    Store.where(store_object_id: store_object_id).where('created_at < ?', 1.month.ago).where.not(o_id: taskbar_form_ids).find_each do |store|
      Store.remove_item(store.id)
    end
  end

  private

  def store_object_id
    Store::Object.lookup(name: 'UploadCache')&.id
  end
end
