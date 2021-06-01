# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Ticket::Article::Type.create_if_not_exists(id: 1, name: 'email', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 2, name: 'sms', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 3, name: 'chat', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 4, name: 'fax', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 5, name: 'phone', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 6, name: 'twitter status', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 7, name: 'twitter direct-message', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 8, name: 'facebook feed post', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 9, name: 'facebook feed comment', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 10, name: 'note', communication: false)
Ticket::Article::Type.create_if_not_exists(id: 11, name: 'web', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 12, name: 'telegram personal-message', communication: true)
