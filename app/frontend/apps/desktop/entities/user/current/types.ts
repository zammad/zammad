// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'

export interface TaskbarTabContext {
  formValues?: FormValues
  formIsDirty?: boolean
  formIsSettled?: boolean

  // Add generic properties to the context (e.g. overview information in ticket detail view context).
  [index: string]: unknown
}
