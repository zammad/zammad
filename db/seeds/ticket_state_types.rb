# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Ticket::StateType.create_if_not_exists(id: 1, name: 'new')
Ticket::StateType.create_if_not_exists(id: 2, name: 'open')
Ticket::StateType.create_if_not_exists(id: 3, name: 'pending reminder')
Ticket::StateType.create_if_not_exists(id: 4, name: 'pending action')
Ticket::StateType.create_if_not_exists(id: 5, name: 'closed')
Ticket::StateType.create_if_not_exists(id: 6, name: 'merged')
Ticket::StateType.create_if_not_exists(id: 7, name: 'removed')
