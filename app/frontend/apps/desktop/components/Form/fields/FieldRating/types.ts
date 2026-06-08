// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export type HorizontalAlignment = 'start' | 'center' | 'end'

export type FieldRatingContext = {
  alignment?: HorizontalAlignment
}

export interface FieldRatingProps {
  context: FormFieldContext<FieldRatingContext>
}
