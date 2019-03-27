FactoryBot.define do
  factory :taskbar do
    client_id                { 123 }
    key                      { 'Ticket-1234' }
    add_attribute(:callback) { 'TicketZoom' }
    params                   { {} }
    state                    {}
    prio                     { 1 }
    notify                   { false }
  end
end
