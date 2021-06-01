# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :group do
    email_address
    sequence(:name) { |n| "Group #{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
