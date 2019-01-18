FactoryBot.define do
  factory :permission do
    name { Faker::Job.unique.position.downcase }
  end
end
