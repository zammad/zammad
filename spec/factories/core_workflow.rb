# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :core_workflow do
    sequence(:name) { |n| "test - workflow #{format '%07d', n}" }
    changeable { false }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
