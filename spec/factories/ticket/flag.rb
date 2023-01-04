# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/flag', aliases: %i[ticket_flag] do
    ticket
    key     { "key_#{Faker::Food.fruits}" }
    value { "value_#{Faker::Food.fruits}" }
    created_by_id { 1 }
  end
end
