FactoryBot.define do
  factory :macro do
    sequence(:name) { |n| "Macro #{n}" }
    perform         { {} }
    ux_flow_next_up { 'next_task' }
    note            { '' }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
