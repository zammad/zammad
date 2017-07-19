FactoryGirl.define do
  factory :ticket do
    title 'Test Ticket'
    group { Group.lookup(name: 'Users') }
    customer { FactoryGirl.create(:customer_user) }
    state { Ticket::State.lookup(name: 'new') }
    priority { Ticket::Priority.lookup(name: '2 normal') }
    updated_by_id 1
    created_by_id 1
  end
end
