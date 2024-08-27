// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectLike } from '#shared/types/utils.ts'

import type { Component } from 'vue'

export enum EntityType {
  User = 'User',
  Organization = 'Organization',
}

export interface Entity<T = ObjectLike> {
  array: T[]
  totalCount: number
}

export interface EntityModule {
  type: EntityType
  component: Component
  emptyMessage: string
}
