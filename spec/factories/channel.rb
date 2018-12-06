FactoryBot.define do
  factory :channel do
    area         'Email::Dummy'
    group        { ::Group.find(1) }
    active       true
    options      {}
    preferences  {}
    updated_by_id 1
    created_by_id 1
  end
end
