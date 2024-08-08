# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'checklist/item', aliases: %i[checklist_item] do
    checklist

    text          { Faker::Lorem.unique.sentence }
    checked       { false }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
