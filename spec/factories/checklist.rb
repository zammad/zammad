# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :checklist do
    name            { '' }
    sorted_item_ids { [] }

    transient do
      create_first_item { true }
    end

    ticket

    transient do
      item_count { 5 }
    end

    after(:create) do |checklist, context|
      next if !context.create_first_item
      next if context.item_count.blank?

      create_list(:checklist_item, context.item_count, checklist: checklist)
    end

    trait :empty do
      transient do
        create_first_item { false }
      end
    end
  end
end
