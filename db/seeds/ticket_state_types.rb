# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Ticket::StateType.create_if_not_exists(id: 1, name: __('new'))
Ticket::StateType.create_if_not_exists(id: 2, name: __('open'))
Ticket::StateType.create_if_not_exists(id: 3, name: __('pending reminder'))
Ticket::StateType.create_if_not_exists(id: 4, name: __('pending action'))
Ticket::StateType.create_if_not_exists(id: 5, name: __('closed'))
Ticket::StateType.create_if_not_exists(id: 6, name: __('merged'))
Ticket::StateType.create_if_not_exists(id: 7, name: __('removed'))
