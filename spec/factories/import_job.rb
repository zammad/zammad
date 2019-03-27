FactoryBot.define do
  factory :import_job do
    name    { 'Import::Test' }
    payload {}
    dry_run { false }
  end
end
