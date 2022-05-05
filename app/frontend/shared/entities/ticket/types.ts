// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// eslint-disable-next-line import/prefer-default-export
export enum TicketState {
  closed = 'closed',
  'waiting-for-closure' = 'waiting-for-closure',
  'waiting-for-reminder' = 'waiting-for-reminder',
  open = 'open',
  escalated = 'escalated',
}
