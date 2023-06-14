# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/time_accounting', aliases: %i[ticket_time_accounting] do
    ticket
    time_unit     { Faker::Number.unique.number(digits: 2) }
    created_by_id { 1 }

    trait :for_article do
      ticket_article { create(:'ticket/article', ticket: ticket) }
    end

    trait :for_type do
      type { create(:ticket_time_accounting_type) }
    end
  end
end
