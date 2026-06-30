// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectLike } from '#shared/types/utils.ts'

export interface EditableOrganization extends ObjectLike {
  id: string
  domainAssignment?: boolean | null
}
