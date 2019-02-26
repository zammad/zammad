FactoryBot.define do
  factory :sla do
    calendar
    sequence(:name) { |n| "SLA #{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    condition do
      {
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
      }
    end
  end
end
