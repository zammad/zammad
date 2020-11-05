FactoryBot.define do
  factory :import_job do
    name    { 'Import::Test' }
    payload { nil }
    dry_run { false }
  end
end
