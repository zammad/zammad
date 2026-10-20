// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { formatDateTimeValue } from './normalizeDateValue.ts'

import type { DateTimeContext } from './types.ts'
import type { Ref, WritableComputedRef } from 'vue'

// The date field value is loosely typed — a date string, a `[from, to]` range
// (whose bounds may be transiently null mid-selection), or null — matching
// `useValue`'s `any` model and assignable to the picker's broad `ModelValue`
// v-model. The runtime guards below narrow it where it matters.
// oxlint-disable-next-line no-explicit-any
type DateModel = any

// Shared model handling between the picker's `v-model` and the form value, used
// by both the desktop and mobile date fields so they behave identically: with
// `partialRange: false`, a half-selected range (`[from, null]`, which the picker
// auto-applies mid-selection) is dropped — only a complete range reaches the
// form value.
export const usePickerModel = (
  context: Ref<DateTimeContext>,
  localValue: WritableComputedRef<DateModel>,
  minDate: Ref<Date | string | undefined>,
  maxDate: Ref<Date | string | undefined>,
) => {
  const pickerModel = computed<DateModel>({
    get: () => localValue.value,
    set: (value) => {
      if (
        context.value.partialRange === false &&
        Array.isArray(value) &&
        (value[0] == null || value[1] == null)
      ) {
        return
      }

      localValue.value = value
    },
  })

  // The picker rejects a day whose 08:00 start time lies outside the bounds (today in a future-
  // or past-only field), so such a click selects the bound instead. Those bounds date from the
  // opening, so the click time is the closer one.
  const outOfRangeBound = (date: Date) => {
    if (minDate.value && date < new Date(minDate.value)) {
      return context.value.futureOnly ? new Date() : new Date(minDate.value)
    }

    if (maxDate.value && date > new Date(maxDate.value)) {
      return context.value.pastOnly ? new Date() : new Date(maxDate.value)
    }

    return null
  }

  const clampDateClick = (date: Date) => {
    if (context.value.type !== 'datetime' || context.value.range) return false

    const bound = outOfRangeBound(date)
    if (!bound) return false

    localValue.value = formatDateTimeValue(bound)

    return true
  }

  return { pickerModel, clampDateClick }
}
