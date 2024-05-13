// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'

export interface NewTokenAccessFormData extends FormValues {
  name: string
  expires_at?: string
  permissions: string[]
}
