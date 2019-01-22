FactoryBot.define do
  factory :'ticket/state_type', aliases: %i[ticket_state_type] do
    name { Faker::Verb.past_participle }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
