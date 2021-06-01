# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'tag/item', aliases: %i[tag_item] do
    sequence(:name) { |n| "Item #{n}" }
  end
end
