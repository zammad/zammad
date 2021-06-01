# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "TestOrganization#{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
