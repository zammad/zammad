# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module BackgroundJobsHelper
  # clear ActiveSupport::CurrentAttributes caches

  # def self.included(base)
  # base.teardown do
  # ActiveSupport::CurrentAttributes.clear_all
  # end
  # end

  def perform_enqueued_jobs(commit_transaction: false, disable_notification: false)
    TransactionDispatcher.commit disable_notification: disable_notification if commit_transaction

    original_interface_handle = ApplicationHandleInfo.current
    ApplicationHandleInfo.current = 'scheduler'

    original_user_id = UserInfo.current_user_id
    UserInfo.current_user_id = nil

    _success, failure = Delayed::Worker.new.work_off

    if failure.nonzero?
      raise "#{failure} failed background jobs: #{Delayed::Job.where.not(last_error: nil).inspect}"
    end
  ensure
    UserInfo.current_user_id = original_user_id
    ApplicationHandleInfo.current = original_interface_handle
  end
end
