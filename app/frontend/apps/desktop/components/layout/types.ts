// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type BoxSizes = 'small' | 'medium' | 'large'

export type ContentWidth = 'narrow' | 'full'

export type BackgroundVariant = 'primary' | 'tertiary'

export enum SidebarPosition {
  Start = 'start',
  End = 'end',
}

export type ContentAlignment = 'center' | 'start'

export enum SidebarName {
  Primary = 'primary',
  TicketContent = 'ticket-content',
  TicketOverviews = 'ticket-overviews',
  PersonalSetting = 'personal-setting',
}

export interface ToggleOptions {
  storage?: 'session' | 'persisted'
}
