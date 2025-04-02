// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  Scalars,
  TaskbarItemEntity,
} from '#shared/graphql/types.ts'

import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'

import type { DocumentNode } from 'graphql'
import type { Component } from 'vue'
import type { RouteLocationNormalizedGeneric } from 'vue-router'

export type UserTaskbarTabEntity = Partial<TaskbarItemEntity> | null

export interface UserTaskbarTab<T = UserTaskbarTabEntity> {
  type: EnumTaskbarEntity
  entity?: T
  entityAccess?: Maybe<EnumTaskbarEntityAccess>
  tabEntityKey: string
  taskbarTabId?: ID
  updatedAt?: Scalars['ISO8601DateTime']['output']
  order: number
  formId?: Maybe<Scalars['FormId']['input']>
  formNewArticlePresent?: boolean
  changed?: boolean
  dirty?: boolean
  notify?: boolean
}

export interface UserTaskbarTabEntityProps<T = UserTaskbarTabEntity> {
  taskbarTab: UserTaskbarTab<T>
  taskbarTabLink?: string
  context?: TaskbarTabContext
}

export interface UserTaskbarTabPlugin<T = UserTaskbarTabEntity> {
  type: EnumTaskbarEntity
  component: Component
  entityType?: string
  entityDocument?: DocumentNode
  buildEntityTabKey: (route: RouteLocationNormalizedGeneric) => string
  buildTaskbarTabEntityId: (
    route: RouteLocationNormalizedGeneric,
  ) => string | undefined
  buildTaskbarTabParams: <T = Record<string, unknown>>(
    route: RouteLocationNormalizedGeneric,
  ) => T
  buildTaskbarTabLink?: (entity?: T, entityKey?: string) => string | undefined
  confirmTabRemove?: boolean
  touchExistingTab?: boolean
}

export interface BackRoute {
  path: string
  taskbarTabEntityKey?: string
}
