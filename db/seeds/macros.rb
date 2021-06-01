# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Macro.create_if_not_exists(
  name:            'Close & Tag as Spam',
  perform:         {
    'ticket.state_id' => {
      value: Ticket::State.by_category(:closed).first.id,
    },
    'ticket.tags'     => {
      operator: 'add',
      value:    'spam',
    },
    'ticket.owner_id' => {
      pre_condition: 'current_user.id',
      value:         '',
    },
  },
  ux_flow_next_up: 'next_task',
  note:            'example macro',
  active:          true,
)
