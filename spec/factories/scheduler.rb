# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :scheduler do
    sequence(:name)        { |n| "Testscheduler#{n}" }
    last_run               { Time.zone.now }
    pid                    { 1337 }
    prio                   { 1 }
    status                 { 'ok' }
    active                 { true }
    period                 { 10.minutes }
    running                { false }
    note                   { 'test' }
    updated_by_id          { 1 }
    created_by_id          { 1 }
    created_at             { 1 }
    updated_at             { 1 }
    add_attribute(:method) { 'test' }

    trait :timeplan do
      timeplan do
        { days:    { Mon: true,
                     Tue: true,
                     Wed: true,
                     Thu: true,
                     Fri: true,
                     Sat: true,
                     Sun: true },
          hours:   { 23 => true },
          minutes: { 0  => true } }
      end
    end
  end
end
