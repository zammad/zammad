// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { AutoCompleteProps } from '../FieldAutocomplete/types.ts'

export interface FieldTagsProps {
  canCreate?: boolean
  sorting?: 'label' | 'value'
  exclude?: string[]
  onDeactivate?: () => void
}

export type FieldTagsContext = FormFieldContext<
  AutoCompleteProps &
    FieldTagsProps & {
      options?: FormFieldContext['options']
    }
>
