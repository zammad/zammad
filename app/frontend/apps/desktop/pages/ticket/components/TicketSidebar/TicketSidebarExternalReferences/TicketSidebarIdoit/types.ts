// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'

export type FormFieldRecords = {
  type: string | undefined
  filter: string | undefined
  objectIds: number[]
}

export type FormDataRecords = FormSubmitData<FormFieldRecords>
