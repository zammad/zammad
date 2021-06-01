# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module DataPrivacyTask::HasActivityStreamLog
  extend ActiveSupport::Concern

  included do
    include ::HasActivityStreamLog
    after_update :log_activity

    activity_stream_permission 'admin.data_privacy'
  end

  def log_activity
    return if !saved_change_to_attribute?('state')
    return if state != 'completed'

    activity_stream_log('completed', created_by_id, true)
  end
end
