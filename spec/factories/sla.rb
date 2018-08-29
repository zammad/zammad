FactoryBot.define do
  factory :sla do
    sequence(:name)     { |n| "SLA #{n}" }
    first_response_time nil
    update_time         nil
    solution_time       nil
    calendar            { create(:calendar) }
    condition           do
      {
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
      }
    end
    created_by_id 1
    updated_by_id 1
  end
end
