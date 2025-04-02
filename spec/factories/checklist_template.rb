# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :checklist_template do
    name            { Faker::Name.unique.name }
    active          { true }
    sorted_item_ids { [] }

    transient do
      item_count { 5 }
    end

    after(:create) do |checklist, context|
      next if context.item_count.blank?

      checklist.replace_items! Array.new(context.item_count) { Faker::Lorem.unique.sentence }
    end
  end
end
