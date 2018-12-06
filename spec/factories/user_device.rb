FactoryBot.define do
  sequence :fingerprint do |n|
    "fingerprint#{n}"
  end
end

FactoryBot.define do

  factory :user_device do
    user_id 1
    name 'test 1'
    location 'some location'
    user_agent 'some user agent'
    ip '127.0.0.1'
    fingerprint { generate(:fingerprint) }
  end

end
