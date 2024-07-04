// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormValues } from '#shared/components/Form/types.ts'

import type { TicketSidebarPlugin } from './TicketSidebar/plugins/types.ts'

export enum TicketSidebarScreenType {
  TicketCreate = 'ticket-create',
  TicketDetailView = 'ticket-detail-view',
}

export interface TicketSidebarContext {
  screenType: TicketSidebarScreenType
  form?: FormRef
  formValues: FormValues
}

export interface TicketSidebarContentProps {
  context: TicketSidebarContext
}

export interface TicketSidebarButtonProps extends TicketSidebarContentProps {
  sidebar: string
  sidebarPlugin: TicketSidebarPlugin
  selected?: boolean
}

export type TicketSidebarButtonEmits = {
  show: []
  hide: []
}

export enum TicketSidebarButtonBadgeType {
  Info = 'info',
  Warning = 'warning',
  Danger = 'danger',
}

export type TicketSidebarButtonBadgeDetails = {
  label: string
  type?: TicketSidebarButtonBadgeType
  value: string | number
}
