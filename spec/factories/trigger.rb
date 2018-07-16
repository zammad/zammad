FactoryBot.define do
  factory :trigger do
    name          { "Test trigger #{rand(2**16)}" } # prevent unique name conflicts
    condition     { { 'ticket.state_id' => { 'operator' => 'is not', 'value' => 4 } } }
    perform       { { 'ticket.state_id' => { 'value' => 4 } } }
    active        true
    created_by_id 1
    updated_by_id 1
  end
end
