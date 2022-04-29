// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

enum TicketState {
  closed = 'closed',
  'waiting-for-closure' = 'waiting-for-closure',
  'waiting-for-reminder' = 'waiting-for-reminder',
  open = 'open',
  escalated = 'escalated',
}

export default TicketState
