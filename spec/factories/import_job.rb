# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :import_job do
    name    { 'Import::Test' }
    payload { nil }
    dry_run { false }
  end
end
