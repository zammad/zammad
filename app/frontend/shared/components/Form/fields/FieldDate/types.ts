// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { RangeConfig } from '@vuepic/vue-datepicker'

export const dateFieldProps = [
  'clearable',
  'futureOnly',
  'maxDate',
  'minDate',
  'range',
]

export type DateTimeContext = FormFieldContext<{
  range?: boolean | RangeConfig
  clearable?: boolean
  futureOnly?: boolean
  maxDate?: Date | string
  minDate?: Date | string
}>
