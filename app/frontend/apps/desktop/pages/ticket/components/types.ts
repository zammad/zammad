// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'

export enum TicketSidebarScreenType {
  TicketCreate = 'ticket-create',
  TicketDetailView = 'ticket-detail-view',
}

export interface TicketSidebarContext {
  screenType: TicketSidebarScreenType
  formValues: FormValues
}

export enum TicketSidebarButtonBadgeType {
  Info = 'info',
  Warning = 'warning',
  Danger = 'danger',
}

export type TicketSidebarButtonBadgeDetails = {
  type?: TicketSidebarButtonBadgeType
  value: string | number
}
