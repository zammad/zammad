// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import type { EnumTicketStateColorCode, TicketBulkSelectorInput } from '#shared/graphql/types.ts'

import type { Ref } from 'vue'

export interface DragAndDropBulkOptions {
  checkedTicketIds: Ref<Set<ID>>
  bulkSelector: Ref<TicketBulkSelectorInput>
}

export enum DragAndDropBulkEntityType {
  Macro = 'macro',
  Group = 'group',
  Owner = 'owner',
}

export interface BulkData {
  internalId: number
  type: DragAndDropBulkEntityType
  groupInternalId: number | null
}

export interface UserOption {
  /**
   * internal id
   */
  value: number
  label: string
  object: AvatarUser
}

interface GroupChild {
  /**
   * internal id
   */
  value: number
  label: string
  disabled: boolean
}
export interface GroupOption extends GroupChild {
  children?: GroupChild[]
}

export interface BulkScrollListItem {
  label: string
  type: DragAndDropBulkEntityType
  object?: AvatarUser
  /**
   * An array of parent group names
   */
  parentLabel?: string
  internalId: number
  groupInternalId?: number
}

export interface DragPreviewData {
  stateColorCode: EnumTicketStateColorCode | null
  /**
   *  If undefined, priority ui icon feature is disabled)
   * */
  priorityUiColor?: string | null
  /**
   * Text content of the first visible text cells
   */
  columnText: string
}
