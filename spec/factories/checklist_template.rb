# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :checklist_template do
    name            { Faker::Name.unique.name }
    updated_by_id   { 1 }
    created_by_id   { 1 }
    active          { true }
    sorted_item_ids { [] }

    transient do
      item_count { 5 }
    end

    after(:create) do |checklist, context|
      next if context.item_count.blank?

      create_list(:checklist_template_item, context.item_count, checklist_template: checklist)
    end
  end
end
