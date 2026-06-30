// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectLike } from '#shared/types/utils.ts'

export interface SignupFormData {
  firstname: string
  lastname: string
  email: string
  password: string
}

export interface EditableUser extends ObjectLike {
  id: string
  organization?: {
    internalId?: number | null
  } | null
}
