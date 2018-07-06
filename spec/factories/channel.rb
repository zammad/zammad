FactoryBot.define do
  factory :channel do
    area        'Email::Dummy'
    group       { ::Group.find(1) }
    active      true
    options     {}
    preferences {}
  end
end
