# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :public_link do
    sequence(:link) { |i| "https://zammad#{i}.com" }
    sequence(:title) { |i| "Zammad Homepage#{i}" }
    description   { 'Our fancy homepage.' }
    screen        { ['login'] }
    new_tab       { true }
    prio          { 1 }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
