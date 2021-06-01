# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :permission do
    name { Faker::Job.unique.position.downcase }
  end
end
