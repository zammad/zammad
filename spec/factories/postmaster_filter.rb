# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :postmaster_filter do
    sequence(:name) { |n| "Test PostmasterFilter #{n}" }
    channel         { 'email' }
    match           { { 'from' => { 'operator' => 'contains', 'value' => 'a' } } }
    perform         { { 'x-zammad-ticket-tags' => { 'operator' => 'remove', 'value' => 'test2, test7' } } }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
