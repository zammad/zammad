// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export enum TicketState {
  Closed = 'closed',
  WaitingForClosure = 'waiting-for-closure',
  WaitingForReminder = 'waiting-for-reminder',
  Open = 'open',
  Escalated = 'escalated',
}
