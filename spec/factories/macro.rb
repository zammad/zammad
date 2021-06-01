# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :macro do
    sequence(:name) { |n| "Macro #{n}" }
    perform         { { 'ticket.state_id' => { 'value' => 1 } } }
    ux_flow_next_up { 'next_task' }
    note            { '' }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
