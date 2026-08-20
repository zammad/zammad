// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { TableItem } from '#desktop/components/CommonTable/types.ts'

export enum KnowledgeBaseAccess {
  Editor = 'editor',
  Reader = 'reader',
  None = 'none',
}

/**
 * One row of the matrix, as delivered by the form updater. Carries no access of its own — which
 * one is picked is the field's value — only who the row is for and what may be picked in it.
 */
export interface KnowledgeBasePermissionRow {
  roleId: string
  roleName: string
  /** What the role gets from the parent when the row is left alone, `null` when nothing is inherited. */
  inheritedAccess?: KnowledgeBaseAccess | null
  /** The levels this role may legally be given here; everything else is locked. */
  allowedAccesses: KnowledgeBaseAccess[]
}

export type KnowledgeBasePermissions = Record<string, KnowledgeBaseAccess>

export type KnowledgeBasePermissionsContext = FormFieldContext<{
  permissionRows?: KnowledgeBasePermissionRow[]
}>

export interface PermissionsTableItem extends TableItem {
  id: string
  role: string
  inheritedAccess?: KnowledgeBaseAccess | null
  allowedAccesses: KnowledgeBaseAccess[]
}
