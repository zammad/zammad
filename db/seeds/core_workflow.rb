# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

CoreWorkflow.create_if_not_exists(
  name:            'base - hide pending time on non pending states',
  object:          'Ticket',
  condition_saved: {
    'custom.module': {
      operator: 'match all modules',
      value:    [
        'CoreWorkflow::Custom::PendingTime',
      ],
    },
  },
  perform:         {
    'custom.module': {
      execute: ['CoreWorkflow::Custom::PendingTime']
    },
  },
  changeable:      false,
  created_by_id:   1,
  updated_by_id:   1,
)
CoreWorkflow.create_if_not_exists(
  name:            'base - admin sla options',
  object:          'Sla',
  condition_saved: {
    'custom.module': {
      operator: 'match all modules',
      value:    [
        'CoreWorkflow::Custom::AdminSla',
      ],
    },
  },
  perform:         {
    'custom.module': {
      execute: ['CoreWorkflow::Custom::AdminSla']
    },
  },
  changeable:      false,
  created_by_id:   1,
  updated_by_id:   1,
)
CoreWorkflow.create_if_not_exists(
  name:            'base - core workflow',
  object:          'CoreWorkflow',
  condition_saved: {
    'custom.module': {
      operator: 'match all modules',
      value:    [
        'CoreWorkflow::Custom::AdminCoreWorkflow',
      ],
    },
  },
  perform:         {
    'custom.module': {
      execute: ['CoreWorkflow::Custom::AdminCoreWorkflow']
    },
  },
  changeable:      false,
  created_by_id:   1,
  updated_by_id:   1,
)
CoreWorkflow.create_if_not_exists(
  name:               'base - show reopen_time_in_days',
  object:             'Group',
  condition_saved:    {},
  condition_selected: { 'group.follow_up_possible'=>{ 'operator' => 'is', 'value' => ['new_ticket_after_certain_time'] } },
  perform:            { 'group.reopen_time_in_days'=>{ 'operator' => 'show', 'show' => 'true' } },
  preferences:        { 'screen'=>%w[create edit] },
  changeable:         false,
  active:             true,
  created_by_id:      1,
  updated_by_id:      1,
)
