// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  Scalars,
} from '#shared/graphql/types.ts'
import type { ObjectWithId, ObjectWithUid } from '#shared/types/utils.ts'

import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'

import type { DocumentNode } from 'graphql'
import type { Component } from 'vue'

export interface UserTaskbarTab<T = Maybe<ObjectWithId | ObjectWithUid>> {
  type: EnumTaskbarEntity
  entity?: T
  entityAccess?: Maybe<EnumTaskbarEntityAccess>
  tabEntityKey: string
  taskbarTabId?: ID
  lastContact: Scalars['ISO8601DateTime']['output']
  updatedAt?: Scalars['ISO8601DateTime']['output']
  order: number
  formId?: Maybe<Scalars['FormId']['input']>
  changed?: boolean
  dirty?: boolean
  notify?: boolean
}

export interface UserTaskbarTabEntityProps<T = ObjectWithId> {
  taskbarTab: UserTaskbarTab<T>
  taskbarTabLink?: string
  context?: TaskbarTabContext
}

export interface UserTaskbarTabPlugin {
  type: EnumTaskbarEntity
  component: Component
  entityType?: string
  entityDocument?: DocumentNode
  buildEntityTabKey: (entityInternalId: string | number) => string
  buildTaskbarTabParams: <T = Record<string, unknown>>(
    entityInternalId: string | number,
  ) => T
  buildTaskbarTabLink?: (
    entity?: ObjectWithId | ObjectWithUid | null,
  ) => string | undefined
  confirmTabRemove?: (dirty?: boolean) => Promise<boolean>
}
