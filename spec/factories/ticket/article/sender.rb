FactoryBot.define do
  factory :'ticket/article/sender', aliases: %i[ticket_article_sender] do
    sequence(:name) { |n| "#{n} sender" }
    updated_by_id   { 1 }
    created_by_id   { 1 }
  end
end
