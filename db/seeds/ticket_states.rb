# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Ticket::State.create_if_not_exists(
  id:             1,
  name:           __('new'),
  state_type_id:  Ticket::StateType.find_by(name: 'new').id,
  default_create: true,
)
Ticket::State.create_if_not_exists(
  id:                2,
  name:              __('open'),
  state_type_id:     Ticket::StateType.find_by(name: 'open').id,
  default_follow_up: true,
)
Ticket::State.create_if_not_exists(
  id:                3,
  name:              __('pending reminder'),
  state_type_id:     Ticket::StateType.find_by(name: 'pending reminder').id,
  ignore_escalation: true,
)
Ticket::State.create_if_not_exists(
  id:                4,
  name:              __('closed'),
  state_type_id:     Ticket::StateType.find_by(name: 'closed').id,
  ignore_escalation: true,
)
Ticket::State.create_if_not_exists(
  id:                5,
  name:              __('merged'),
  state_type_id:     Ticket::StateType.find_by(name: 'merged').id,
  ignore_escalation: true,
)
Ticket::State.create_if_not_exists(
  id:                6,
  name:              __('removed'),
  state_type_id:     Ticket::StateType.find_by(name: 'removed').id,
  active:            false,
  ignore_escalation: true,
)
Ticket::State.create_if_not_exists(
  id:                7,
  name:              __('pending close'),
  state_type_id:     Ticket::StateType.find_by(name: 'pending action').id,
  next_state_id:     Ticket::State.by_category(:closed).first.id,
  ignore_escalation: true,
)
