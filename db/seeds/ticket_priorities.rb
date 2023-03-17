# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Ticket::Priority.create_if_not_exists(id: 1, name: __('1 low'), ui_icon: 'low-priority', ui_color: 'low-priority')
Ticket::Priority.create_if_not_exists(id: 2, name: __('2 normal'), default_create: true)
Ticket::Priority.create_if_not_exists(id: 3, name: __('3 high'), ui_icon: 'important', ui_color: 'high-priority')
