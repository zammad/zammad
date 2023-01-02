# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :import_job do
    name    { 'Import::Test' }
    payload { nil }
    dry_run { false }
  end
end
