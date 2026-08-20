// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'
import type { EnumKnowledgeBasePermissionAccess } from '#shared/graphql/types.ts'

// What the fields hold on submit. `parentId` carries a raw record id (the option values
//   the updater serves), and `permissions` an access per role id — both need converting
//   before they can go out as GraphQL ids. The access levels are spelled with the schema
//   enum rather than the matrix field's own copy of it; the two hold the same values, and
//   this is the end that has to satisfy the mutation input.
export interface CategoryFormData extends FormValues {
  title: string
  categoryIcon: string
  parentId?: number | string | null
  permissions?: Record<string, EnumKnowledgeBasePermissionAccess>
}
