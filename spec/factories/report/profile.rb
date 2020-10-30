FactoryBot.define do
  factory :'report/profile', aliases: %i[report_profile] do
    sequence(:name) { |n| "Report #{n}" }
    active { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
