# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :checklist do
    name            { '' }
    updated_by_id   { 1 }
    created_by_id   { 1 }
    sorted_item_ids { [] }

    ticket { association :ticket, **{ group: Group.first }.compact }

    transient do
      item_count { 5 }
    end

    after(:create) do |checklist, context|
      next if context.item_count.blank?

      create_list(:checklist_item, context.item_count, checklist: checklist)
    end
  end
end
