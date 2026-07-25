// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'

export type FormFieldRecords = {
  category: string | undefined
  model: string | undefined
  filter: string | undefined
  assetIds: number[]
}

export type FormDataRecords = FormSubmitData<FormFieldRecords>
