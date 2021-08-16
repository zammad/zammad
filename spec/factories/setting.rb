# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :setting do
    title       { 'ABC API Token' }
    name        { Faker::Name.unique.name }
    area        { 'Integration::ABC' }
    description { 'API Token for ABC to access ABC.' }
    frontend    { false }
  end
end
