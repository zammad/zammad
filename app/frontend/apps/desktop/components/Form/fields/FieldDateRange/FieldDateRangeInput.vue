<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { TimeOfDay } from '#shared/components/Form/fields/FieldDate/types.ts'
import { toDate } from '#shared/components/Form/fields/FieldDate/useCalendar.ts'
import type {
  DateRangeContext,
  DateRangeValue,
} from '#shared/components/Form/fields/FieldDateRange/types.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'

interface Props {
  context: DateRangeContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { hasValue, localValue } = useValue<DateRangeValue | null>(contextReactive)

const start = ref<string | null>(null)
const end = ref<string | null>(null)

watch(
  localValue,
  (value) => {
    const [newStart, newEnd] = Array.isArray(value) ? value : []

    start.value = newStart ?? null
    end.value = newEnd ?? null
  },
  { immediate: true },
)

// The pickers already settle their own input, so the range commits at once. Each picker refuses
// a typed bound beyond the other one; a reversed range arriving from outside is swapped by the
// `healDateRange` feature, and the pickers follow.
// Without partial ranges a cleared bound empties the value rather than leaving the old range
// behind a half-empty row, so a required field complains instead of saving stale bounds.
const commitRange = () => {
  const partial = !start.value || !end.value

  if ((!start.value && !end.value) || (partial && contextReactive.value.partialRange === false)) {
    if (hasValue.value) contextReactive.value.node.input(null, false)
    return
  }

  const range: DateRangeValue = [start.value, end.value]

  if (!isEqual(range, localValue.value)) contextReactive.value.node.input(range, false)
}

const updateStart = (value: unknown) => {
  start.value = typeof value === 'string' && value ? value : null
  commitRange()
}

const updateEnd = (value: unknown) => {
  end.value = typeof value === 'string' && value ? value : null
  commitRange()
}

// A bound without a typed time covers its whole day, unlike the morning default of a single field.
const START_TIME: TimeOfDay = { hours: 0, minutes: 0 }
const END_TIME: TimeOfDay = { hours: 23, minutes: 59 }

const startId = computed(() => `${contextReactive.value.id}_start`)
const endId = computed(() => `${contextReactive.value.id}_end`)

// Both pickers share everything but their side's bound, value and default time.
const pickerProps = computed(() => {
  const { alternativeBackground, clearable, disabled, futureOnly, pastOnly, withTime } =
    contextReactive.value

  return {
    type: withTime ? ('datetime' as const) : ('date' as const),
    outerClass: 'w-full min-w-0 grow basis-0',
    ignore: true,
    clearable,
    pastOnly,
    futureOnly,
    disabled,
    alternativeBackground,
  }
})

// Each picker stays within the other one's value and the configured bound, whichever is tighter,
// so the calendars can pick neither a reversed range nor a date outside the bounds.
const tighterBound = (
  value: string | null,
  bound: Date | string | undefined,
  isTighter: (date: Date, limit: Date) => boolean,
) => {
  const date = toDate(value)
  const limit = toDate(bound)

  if (!date || (limit && !isTighter(date, limit))) return bound

  return value ?? undefined
}

const startMaxDate = computed(() =>
  tighterBound(end.value, contextReactive.value.maxDate, (date, limit) => date < limit),
)
const endMinDate = computed(() =>
  tighterBound(start.value, contextReactive.value.minDate, (date, limit) => date > limit),
)

const { delegateFocus } = useDelegateFocus(contextReactive.value.id, startId.value)
</script>

<template>
  <output
    :id="context.id"
    class="flex w-full items-center justify-between gap-2"
    :class="context.classes.input"
    role="group"
    :aria-labelledby="`label-${context.id}`"
    :aria-describedby="context.describedBy"
    :aria-disabled="context.disabled"
    tabindex="-1"
    v-bind="context.attrs"
    data-test-id="field-daterange"
    @focus="delegateFocus"
  >
    <FormKit
      :id="startId"
      v-bind="pickerProps"
      :model-value="start"
      :aria-label="$t('Start date')"
      :min-date="context.minDate"
      :max-date="startMaxDate"
      :default-time="START_TIME"
      @input-raw="updateStart"
      @blur="context.handlers.blur"
    />
    <span class="flex h-10 shrink-0 items-center" aria-hidden="true">-</span>
    <FormKit
      :id="endId"
      v-bind="pickerProps"
      :model-value="end"
      :aria-label="$t('End date')"
      :min-date="endMinDate"
      :max-date="context.maxDate"
      :default-time="END_TIME"
      @input-raw="updateEnd"
      @blur="context.handlers.blur"
    />
  </output>
</template>
