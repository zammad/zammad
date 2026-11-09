// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { DateFieldProps } from '#shared/components/Form/fields/FieldDate/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export const dateRangeFieldProps = [
  'alternativeBackground',
  'clearable',
  'futureOnly',
  'maxDate',
  'minDate',
  'partialRange',
  'pastOnly',
  'withTime',
]

export type DateRangeValue = [string | null, string | null]

export type DateRangeContext = FormFieldContext<
  Pick<
    DateFieldProps,
    'alternativeBackground' | 'clearable' | 'pastOnly' | 'futureOnly' | 'maxDate' | 'minDate'
  > & {
    // Whether a range with one bound still missing reaches the form value as `[start, null]`
    // or `[null, end]`. Defaults to `true`, pass `false` to commit only a complete range.
    partialRange?: boolean
    // Makes the bounds timestamps, picked with a time panel after the day.
    withTime?: boolean
  }
>
