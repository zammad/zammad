FactoryBot.define do
  factory :'tag/item', aliases: %i[tag_item] do
    sequence(:name) { |n| "Item #{n}" }
  end
end
