FactoryBot.define do
  factory :'history/type', aliases: %i[history_type] do
    name { Faker::Verb.past_participle }
  end
end
