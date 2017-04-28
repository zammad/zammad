Ticket::Priority.create_if_not_exists(id: 1, name: '1 low')
Ticket::Priority.create_if_not_exists(id: 2, name: '2 normal', default_create: true)
Ticket::Priority.create_if_not_exists(id: 3, name: '3 high')
