// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

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

  return { pickerModel }
}
