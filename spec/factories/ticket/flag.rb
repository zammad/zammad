FactoryBot.define do
  factory :'ticket/flag', aliases: %i[ticket_flag] do
    ticket
    key     { "key_#{rand(100)}" }
    value { "value_#{rand(100)}" }
    created_by_id { 1 }
  end
end
