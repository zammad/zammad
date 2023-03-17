# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :webhook  do
    sequence(:name) { |n| "Test webhook #{n}" }
    endpoint        { 'http://example.com/endpoint' }
    ssl_verify      { true }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
