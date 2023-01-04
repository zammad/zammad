# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'tag/item', aliases: %i[tag_item] do
    sequence(:name) { |n| "Item #{n}" }
  end
end
