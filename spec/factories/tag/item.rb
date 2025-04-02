# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'tag/item', aliases: %i[tag_item] do
    sequence(:name) { |n| "Item #{n}" }
  end
end
