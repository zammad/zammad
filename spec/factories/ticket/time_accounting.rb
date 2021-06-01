# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/time_accounting', aliases: %i[ticket_time_accounting] do
    ticket
    time_unit     { rand(1..100) }
    created_by_id { 1 }

    trait :for_article do
      ticket_article { create(:'ticket/article', ticket: ticket) }
    end
  end
end
