FactoryBot.define do
  factory :'ticket/state', aliases: %i[ticket_state] do
    name { Faker::Verb.past_participle }
    association :state_type, factory: :'ticket/state_type'
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
