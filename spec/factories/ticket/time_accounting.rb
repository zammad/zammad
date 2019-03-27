FactoryBot.define do
  factory :'ticket/time_accounting', aliases: %i[ticket_time_accounting] do
    ticket
    time_unit     { rand(100) }
    created_by_id { 1 }

    trait :for_article do
      ticket_article { create(:'ticket/article', ticket: ticket) }
    end
  end
end
