// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'
import type { EnumKnowledgeBasePermissionAccess } from '#shared/graphql/types.ts'

// What the fields hold on submit. `permissions` is keyed by raw role id, and needs converting
//   before it can go out as GraphQL ids.
export interface KnowledgeBaseFormData extends FormValues {
  title: string
  footerNote?: string
  permissions?: Record<string, EnumKnowledgeBasePermissionAccess>
}
