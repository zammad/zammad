# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :setting do
    title       { 'ABC API Token' }
    name        { Faker::Color.unique.color_name }
    area        { 'Integration::ABC' }
    description { 'API Token for ABC to access ABC.' }
    frontend    { false }
  end
end
