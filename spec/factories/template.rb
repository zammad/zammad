FactoryBot.define do
  factory :template do
    name          { Faker::Name.unique.name }
    options       { {} }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
