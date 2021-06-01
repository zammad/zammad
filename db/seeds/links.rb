# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Link::Type.create_if_not_exists(id: 1, name: 'normal')
Link::Object.create_if_not_exists(id: 1, name: 'Ticket')
Link::Object.create_if_not_exists(id: 2, name: 'Announcement')
Link::Object.create_if_not_exists(id: 3, name: 'Question/Answer')
Link::Object.create_if_not_exists(id: 4, name: 'Idea')
Link::Object.create_if_not_exists(id: 5, name: 'Bug')
