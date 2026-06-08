// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectLike } from '#shared/types/utils.ts'

import type { Orientation } from '#desktop/components/CommonPopover/types.ts'

import type { Component } from 'vue'

export enum EntityType {
  Organization = 'Organization',
  Ticket = 'Ticket',
  User = 'User',
}

export interface Entity<T = ObjectLike> {
  array: T[]
  totalCount: number
}

export interface EntityModule {
  type: EntityType
  component: () => Promise<Component>
  emptyMessage: string
  hasPopover?: boolean
  popoverOrientation?: Orientation
}
