# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotificationStandalone < ApplicationModel
  validates :kind, inclusion: { in: %w[bulk_job kb_answer_generation_failed] }

  BulkJobData = Data.define(:total, :failed_count)
  KbAnswerGenerationFailedData = Data.define(:error_message, :ticket_title)
end
