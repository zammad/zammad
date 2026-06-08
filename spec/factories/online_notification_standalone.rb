# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :online_notification_standalone do
    bulk_job

    trait :bulk_job do
      data { { total: 123, failed_count: 8 } }
      kind { 'bulk_job' }
    end

    trait :kb_answer_generation_failed do
      data { { error_message: 'AI service unavailable', ticket_title: 'Example ticket' } }
      kind { 'kb_answer_generation_failed' }
    end
  end
end
