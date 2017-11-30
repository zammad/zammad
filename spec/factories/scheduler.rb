FactoryBot.define do
  sequence :test_scheduler_name do |n|
    "Testscheduler#{n}"
  end
end

FactoryBot.define do

  factory :scheduler do
    name          { generate(:test_scheduler_name) }
    last_run      { Time.zone.now }
    pid           1337
    prio          1
    status        'ok'
    active        true
    period        { 10.minutes }
    running       false
    note          'test'
    updated_by_id 1
    created_by_id 1
    created_at    1
    updated_at    1
    add_attribute(:method) { 'test' }
  end
end
