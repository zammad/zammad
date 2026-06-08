# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :checklist_template do
    name            { Faker::Name.unique.name }
    active          { true }
    sorted_item_ids { [] }

    transient do
      item_count { 5 }
      items      { Array.new(item_count) { Faker::Lorem.unique.sentence } }
    end

    after(:create) do |checklist, context|
      next if context.items.blank?

      checklist.replace_items! context.items
    end
  end
end
