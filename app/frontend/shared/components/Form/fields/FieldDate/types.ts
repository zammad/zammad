// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

export type DatePanel = 'year' | 'month' | 'day' | 'time'

export type DateWeekStart = 0 | 1 | 2 | 3 | 4 | 5 | 6

export interface TimeOfDay {
  hours: number
  minutes: number
}

export const dateFieldProps = [
  'alternativeBackground',
  'clearable',
  'defaultTime',
  'disabledDays',
  'futureOnly',
  'maxDate',
  'minDate',
  'pastOnly',
  'weekStart',
]

// The display format follows the user's locale and the value format the field type (`yyyy-MM-dd`
// for `date`, ISO 8601 for `datetime`, which adds the time panel), so neither is configurable.
export interface DateFieldProps {
  alternativeBackground?: boolean
  clearable?: boolean
  pastOnly?: boolean
  futureOnly?: boolean
  maxDate?: Date | string
  minDate?: Date | string
  disabledDays?: (date: Date) => boolean
  // The time a date gets until one is typed or picked. Defaults to 08:00, like in the legacy UI.
  defaultTime?: TimeOfDay
  weekStart?: DateWeekStart
}

export type DateFieldContext = FormFieldContext<DateFieldProps>

declare module '@formkit/inputs' {
  // oxlint-disable-next-line no-unused-vars
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    datetime: DateFieldProps & {
      type: 'datetime'
      value?: string | null
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    datetime: FormKitBaseSlots<Props>
  }
}
