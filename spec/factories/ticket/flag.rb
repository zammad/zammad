# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/flag', aliases: %i[ticket_flag] do
    ticket
    key     { "key_#{Faker::Food.fruits}" }
    value { "value_#{Faker::Food.fruits}" }
    created_by_id { 1 }
  end
end
