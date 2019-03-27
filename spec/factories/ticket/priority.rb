FactoryBot.define do
  factory :'ticket/priority', aliases: %i[ticket_priority] do
    sequence(:name) { |n| "#{n} urgent" }
    updated_by_id   { 1 }
    created_by_id   { 1 }
  end
end
