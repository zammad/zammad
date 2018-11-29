FactoryBot.define do

  factory :overview do
    name 'My Factory Tickets'
    link 'my_factory_tickets'
    prio 1100
    role_ids { [ Role.find_by(name: 'Customer').id, Role.find_by(name: 'Agent').id, Role.find_by(name: 'Admin').id ] }
    out_of_office true
    condition do
      {
        'ticket.state_id' => {
          operator: 'is',
          value: [ Ticket::State.lookup(name: 'new').id, Ticket::State.lookup(name: 'open').id ],
        },
      }
    end
    order do
      {
        by: 'created_at',
        direction: 'DESC',
      }
    end
    view do
      {
        d: %w[title customer state created_at],
        s: %w[number title state created_at],
        m: %w[number title state created_at],
        view_mode_default: 's',
      }
    end
    updated_by_id 1
    created_by_id 1
  end
end
