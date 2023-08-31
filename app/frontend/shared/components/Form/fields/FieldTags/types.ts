// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export interface FieldTagsProps {
  options: FormFieldContext['options']
  disabled?: boolean
  canCreate?: boolean
  sorting?: 'label' | 'value'
}

export type FieldTagsContext = FormFieldContext<FieldTagsProps>
