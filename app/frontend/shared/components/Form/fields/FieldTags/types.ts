// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export interface FieldTagsProps {
  canCreate?: boolean
  sorting?: 'label' | 'value'
}

export type FieldTagsContext = FormFieldContext<
  FieldTagsProps & {
    options: FormFieldContext['options']
  }
>
