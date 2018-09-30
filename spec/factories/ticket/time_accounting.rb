FactoryBot.define do
  factory :ticket_time_accounting, class: Ticket::TimeAccounting do
    ticket
    time_unit { rand(100) }
    created_by_id 1
  end
end
