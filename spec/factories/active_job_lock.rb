# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :active_job_lock do
    lock_key { 'UniqueActiveJob' }
    active_job_id { SecureRandom.uuid }
  end
end
