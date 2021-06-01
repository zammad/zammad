# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :text_module do
    name          { "text module #{Faker::Number.unique.number(3)}" }
    keywords      { Faker::Superhero.prefix }
    content       { Faker::Lorem.sentence }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
