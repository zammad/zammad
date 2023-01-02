# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :type_lookup do
    name do
      # The following line ensures that the name generated by Faker
      # does not conflict with any existing names in the DB.
      Faker::Verb.unique.exclude(:past_participle, [], TypeLookup.pluck(:name))

      Faker::Verb.unique.past_participle
    end
  end
end
