// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export enum TicketState {
  Closed = 'closed',
  WaitingForClosure = 'waiting-for-closure',
  WaitingForReminder = 'waiting-for-reminder',
  Open = 'open',
  Escalated = 'escalated',
  New = 'new',
}
