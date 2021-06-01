# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :trigger do
    sequence(:name) { |n| "Test trigger #{n}"  }
    condition       { { 'ticket.state_id' => { 'operator' => 'is not', 'value' => 4 } } }
    perform         { { 'ticket.state_id' => { 'value' => 4 } } }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
