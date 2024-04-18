// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'

export interface OutOfOfficeFormData extends FormValues {
  text?: string
  date_range?: string[]
  replacement_id?: number
  enabled: boolean
}
