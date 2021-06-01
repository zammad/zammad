# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :job do
    sequence(:name) { |n| "Test job #{n}" }
    condition       { { 'ticket.state_id' => { 'operator' => 'is not', 'value' => 4 } } }
    perform         { { 'ticket.state_id' => { 'value' => 4 } } }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    timeplan do
      { days:    { Mon: true,
                   Tue: false,
                   Wed: false,
                   Thu: false,
                   Fri: false,
                   Sat: false,
                   Sun: false },
        hours:   { 0  => true,
                   1  => false,
                   2  => false,
                   3  => false,
                   4  => false,
                   5  => false,
                   6  => false,
                   7  => false,
                   8  => false,
                   9  => false,
                   10 => false,
                   11 => false,
                   12 => false,
                   13 => false,
                   14 => false,
                   15 => false,
                   16 => false,
                   17 => false,
                   18 => false,
                   19 => false,
                   20 => false,
                   21 => false,
                   22 => false,
                   23 => false },
        minutes: { 0  => true,
                   10 => false,
                   20 => false,
                   30 => false,
                   40 => false,
                   50 => false } }
    end

    trait :always_on do
      timeplan do
        { days:    { Mon: true,
                     Tue: true,
                     Wed: true,
                     Thu: true,
                     Fri: true,
                     Sat: true,
                     Sun: true },
          hours:   { 0  => true,
                     1  => true,
                     2  => true,
                     3  => true,
                     4  => true,
                     5  => true,
                     6  => true,
                     7  => true,
                     8  => true,
                     9  => true,
                     10 => true,
                     11 => true,
                     12 => true,
                     13 => true,
                     14 => true,
                     15 => true,
                     16 => true,
                     17 => true,
                     18 => true,
                     19 => true,
                     20 => true,
                     21 => true,
                     22 => true,
                     23 => true },
          minutes: { 0  => true,
                     10 => true,
                     20 => true,
                     30 => true,
                     40 => true,
                     50 => true } }
      end
    end

    trait :never_on do
      timeplan do
        { days:    { Mon: false,
                     Tue: false,
                     Wed: false,
                     Thu: false,
                     Fri: false,
                     Sat: false,
                     Sun: false },
          hours:   { 0  => false,
                     1  => false,
                     2  => false,
                     3  => false,
                     4  => false,
                     5  => false,
                     6  => false,
                     7  => false,
                     8  => false,
                     9  => false,
                     10 => false,
                     11 => false,
                     12 => false,
                     13 => false,
                     14 => false,
                     15 => false,
                     16 => false,
                     17 => false,
                     18 => false,
                     19 => false,
                     20 => false,
                     21 => false,
                     22 => false,
                     23 => false },
          minutes: { 0  => false,
                     10 => false,
                     20 => false,
                     30 => false,
                     40 => false,
                     50 => false } }
      end
    end
  end
end
