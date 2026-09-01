# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :import_job do
    name    { 'Import::Test' }
    payload { nil }
    dry_run { false }

    # a job that was started and then killed by a restart of the background worker
    trait :interrupted do
      started_at  { 2.days.ago }
      updated_at  { 2.days.ago }
      finished_at { nil }
    end
  end
end
