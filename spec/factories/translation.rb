# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :translation do
    locale            { 'de-de' }
    sequence(:source) { |n| "source#{n}" }
    sequence(:target) { |n| "target#{n}" }
    created_by_id     { 1 }
    updated_by_id     { 1 }
  end
end
