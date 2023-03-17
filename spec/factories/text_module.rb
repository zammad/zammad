# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :text_module do
    name          { "text module #{Faker::Number.unique.number(digits: 3)}" }
    keywords      { Faker::Superhero.prefix }
    content       { Faker::Lorem.sentence }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
