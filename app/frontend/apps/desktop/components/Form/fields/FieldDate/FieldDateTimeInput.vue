<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<!-- eslint-disable zammad/zammad-detect-translatable-string -->

<script setup lang="ts">
import { getNode, type FormKitNode } from '@formkit/core'
import VueDatePicker, { type DatePickerInstance } from '@vuepic/vue-datepicker'
import { isValid, format, formatISO, parse, parseISO } from 'date-fns'
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, nextTick, ref, toRef, watch } from 'vue'
import { IMask, useIMask } from 'vue-imask'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { DateTimeContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { useDateTime } from '#shared/components/Form/fields/FieldDate/useDateTime.ts'
import dateRange from '#shared/form/validation/rules/date-range.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useThemeStore } from '#desktop/stores/theme.ts'

import '@vuepic/vue-datepicker/dist/main.css'

interface Props {
  context: DateTimeContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue(contextReactive)

const {
  ariaLabels,
  displayFormat,
  is24,
  localeStore,
  minDate,
  position,
  timePicker,
  valueFormat,
} = useDateTime(contextReactive)

const config = computed(() => ({
  keepActionRow: true,
  arrowLeft:
    localeStore.localeData?.dir === EnumTextDirection.Rtl
      ? 'calc(100% - 17px)'
      : '17px',
}))

const actionRow = computed(() => ({
  showSelect: false,
  showCancel: false,
  // Do not show 'Today' for range selection, because it will close the picker
  //   even if only one date was selected.
  showNow: !props.context.range,
  showPreview: false,
}))

const inputIcon = computed(() => {
  if (contextReactive.value.range) return 'calendar-range'
  if (timePicker.value) return 'calendar-date-time'
  return 'calendar-event'
})

const picker = ref<DatePickerInstance>()

const { isDarkMode } = storeToRefs(useThemeStore())

const localeFormat = computed(() => {
  if (timePicker.value) return i18n.getDateTimeFormat()
  return i18n.getDateFormat()
})

// Date/time placeholders used in the locale format:
// - 'dd' - 2-digit day
// - 'd' - day
// - 'mm' - 2-digit month
// - 'm' - month
// - 'yyyy' - year
// - 'yy' - last 2 digits of year
// - 'SS' - 2-digit second
// - 'MM' - 2-digit minute
// - 'HH' - 2-digit hour (24h)
// - 'l' - hour (12h)
// - 'P' - Meridian indicator ('am' or 'pm')
const inputFormat = computed(() =>
  localeFormat.value
    .replace(/MM/, '2DigitMinute') // 'MM' is used for both minute and month
    .replace(/mm/, 'MM')
    .replace(/m/, 'M')
    .replace(/SS/, 'ss')
    .replace(/2DigitMinute/, 'mm')
    .replace(/l/, 'hh')
    .replace(/P/, 'aaa'),
)

const maskOptions = computed(() => ({
  mask: contextReactive.value.range
    ? `${localeFormat.value} - ${localeFormat.value}`
    : localeFormat.value,
  blocks: {
    d: {
      mask: IMask.MaskedRange,
      from: 1,
      to: 31,
      placeholderChar: 'D',
    },
    dd: {
      mask: IMask.MaskedRange,
      from: 1,
      to: 31,
      placeholderChar: 'D',
    },
    m: {
      mask: IMask.MaskedRange,
      from: 1,
      to: 12,
      placeholderChar: 'M',
    },
    mm: {
      mask: IMask.MaskedRange,
      from: 1,
      to: 12,
      placeholderChar: 'M',
    },
    yyyy: {
      mask: IMask.MaskedRange,
      from: 1900,
      to: 2100,
      placeholderChar: 'Y',
    },
    yy: {
      mask: IMask.MaskedRange,
      from: 0,
      to: 99,
      placeholderChar: 'Y',
    },
    ss: {
      mask: IMask.MaskedRange,
      from: 0,
      to: 59,
      placeholderChar: 's',
    },
    MM: {
      mask: IMask.MaskedRange,
      from: 0,
      to: 59,
      placeholderChar: 'm',
    },
    HH: {
      mask: IMask.MaskedRange,
      from: 0,
      to: 23,
      placeholderChar: 'h',
    },
    l: {
      mask: IMask.MaskedRange,
      from: 1,
      to: 12,
      placeholderChar: 'h',
    },
    P: {
      mask: IMask.MaskedEnum,
      enum: ['am', 'pm'],
      placeholderChar: 'p',
    },
  },
  autofix: true,
  lazy: false,
  overwrite: true,
}))

const { el, masked, unmasked } = useIMask(maskOptions)

const parseValue = (value: string) => {
  if (valueFormat.value === 'iso') return parseISO(value)
  return parse(value, valueFormat.value, new Date())
}

const formatValue = (value: Date) => {
  if (valueFormat.value === 'iso') return formatISO(value)
  return format(value, valueFormat.value)
}

watch(
  localValue,
  (newValue) => {
    if (!newValue) {
      masked.value = '' // clear input
      return
    }

    if (contextReactive.value.range) {
      const [startValue, endValue] = newValue
      if (!startValue || !endValue) return

      const startDate = parseValue(startValue)
      const endDate = parseValue(endValue)
      if (!isValid(startDate) || !isValid(endDate)) return

      const value = `${format(startDate, inputFormat.value)} - ${format(endDate, inputFormat.value)}`
      if (masked.value === value) return

      masked.value = `${format(startDate, inputFormat.value)} - ${format(endDate, inputFormat.value)}`

      return
    }

    const newDate = parseValue(newValue)
    const maskedDate = parse(masked.value, inputFormat.value, new Date())

    if (
      isValid(maskedDate) &&
      maskedDate.toISOString() === newDate.toISOString()
    )
      return

    masked.value = format(newDate, inputFormat.value)
  },
  {
    immediate: true,
  },
)

const dateRangeValidation = (value: (string | undefined)[]) => {
  if (value.includes(undefined)) return false
  if (dateRange.rule({ value } as FormKitNode<string[]>)) return true

  const node = getNode(contextReactive.value.id)
  if (!node) return

  // Manually set validation error message.
  node.setErrors(i18n.t(dateRange.localeMessage()))

  return false
}

watch(masked, (newValue) => {
  // empty input
  if (localValue.value && (!newValue || !unmasked.value)) {
    localValue.value = null
    return
  }

  if (contextReactive.value.range) {
    const newValues = newValue.split(' - ').map((value) => {
      const date = parse(value, inputFormat.value, new Date())
      if (!isValid(date)) return
      return formatValue(date)
    })

    if (!dateRangeValidation(newValues) || isEqual(localValue.value, newValues))
      return

    localValue.value = newValues

    return
  }

  const newDate = parse(newValue, inputFormat.value, new Date())

  if (
    !isValid(newDate) ||
    (isValid(newDate) && localValue.value === formatValue(newDate))
  )
    return

  localValue.value = formatValue(newDate)
})

const open = () => {
  nextTick(() => {
    testFlags.set('field-date-time.opened')
  })
}

const closed = () => {
  nextTick(() => {
    testFlags.set('field-date-time.closed')
  })

  if (!localValue.value && masked.value) {
    masked.value = '' // clear input
    return
  }

  if (contextReactive.value.range) {
    const maskedValues = masked.value.split(' - ').map((value: string) => {
      const date = parse(value, inputFormat.value, new Date())
      if (!isValid(date)) return
      return formatValue(date)
    })

    if (isEqual(localValue.value, maskedValues)) return

    const [startValue, endValue] = localValue.value
    if (!startValue || !endValue) return

    const startDate = parseValue(startValue)
    const endDate = parseValue(endValue)
    if (!isValid(startDate) || !isValid(endDate)) return

    masked.value = `${format(startDate, inputFormat.value)} - ${format(endDate, inputFormat.value)}`

    return
  }

  const maskedDate = parse(masked.value, inputFormat.value, new Date())

  if (isValid(maskedDate) && localValue.value === formatValue(maskedDate))
    return

  const newDate = parseValue(localValue.value)
  masked.value = format(newDate, inputFormat.value)
}
</script>

<template>
  <div class="w-full">
    <!-- eslint-disable vuejs-accessibility/aria-props   -->
    <VueDatePicker
      ref="picker"
      v-model="localValue"
      :uid="context.id"
      :model-type="valueFormat"
      :name="context.node.name"
      :clearable="!!context.clearable"
      :disabled="context.disabled"
      :range="context.range"
      :enable-time-picker="timePicker"
      :format="displayFormat"
      :is-24="is24"
      :dark="isDarkMode"
      :locale="i18n.locale()"
      :max-date="context.maxDate"
      :min-date="minDate"
      :start-date="minDate || context.maxDate"
      :ignore-time-validation="!timePicker"
      :prevent-min-max-navigation="
        Boolean(minDate || context.maxDate || context.futureOnly)
      "
      :now-button-label="$t('Today')"
      :position="position"
      :action-row="actionRow"
      :config="config"
      :aria-labels="ariaLabels"
      :text-input="{ openMenu: 'open' }"
      auto-apply
      offset="12"
      @open="open"
      @closed="closed"
      @blur="context.handlers.blur"
    >
      <template #dp-input>
        <input
          :id="context.id"
          ref="el"
          :name="context.node.name"
          :class="context.classes.input"
          :disabled="context.disabled"
          :aria-describedby="context.describedBy"
          v-bind="context.attrs"
          type="text"
        />
      </template>
      <template #input-icon>
        <CommonIcon
          :name="inputIcon"
          size="tiny"
          decorative
          @click.stop="picker?.toggleMenu()"
        />
      </template>
      <template #clear-icon>
        <CommonIcon
          class="me-3"
          name="x-lg"
          size="xs"
          tabindex="0"
          role="button"
          :aria-label="$t('Clear Selection')"
          @click.stop="picker?.clearValue()"
        />
      </template>
      <template #clock-icon>
        <CommonIcon name="clock" size="tiny" decorative />
      </template>
      <template #calendar-icon>
        <CommonIcon name="calendar" size="tiny" decorative />
      </template>
      <template #arrow-left>
        <CommonIcon name="chevron-left" size="xs" decorative />
      </template>
      <template #arrow-right>
        <CommonIcon name="chevron-right" size="xs" decorative />
      </template>
      <template #arrow-up>
        <CommonIcon name="chevron-up" size="xs" decorative />
      </template>
      <template #arrow-down>
        <CommonIcon name="chevron-down" size="xs" decorative />
      </template>
    </VueDatePicker>
  </div>
</template>

<style scoped>
:deep(.dp__theme_light) {
  --dp-background-color: var(--color-white);
  --dp-text-color: var(--color-black);
  --dp-hover-color: var(--color-blue-600);
  --dp-hover-text-color: var(--color-black);
  --dp-hover-icon-color: var(--color-blue-800);
  --dp-primary-color: var(--color-blue-800);
  --dp-primary-disabled-color: var(--color-blue-500);
  --dp-primary-text-color: var(--color-white);
  --dp-secondary-color: var(--color-stone-200);
  --dp-border-color: transparent;
  --dp-menu-border-color: var(--color-neutral-100);
  --dp-border-color-hover: transparent;
  --dp-disabled-color: transparent;
  --dp-disabled-color-text: var(--color-stone-200);
  --dp-scroll-bar-background: var(--color-blue-200);
  --dp-scroll-bar-color: var(--color-stone-200);
  --dp-success-color: var(--color-green-500);
  --dp-success-color-disabled: var(--color-green-300);
  --dp-icon-color: var(--color-stone-200);
  --dp-danger-color: var(--color-red-500);
  --dp-marker-color: var(--color-blue-600);
  --dp-tooltip-color: var(--color-blue-200);
  --dp-highlight-color: var(--color-blue-800);
  --dp-range-between-dates-background-color: var(--color-blue-500);
  --dp-range-between-dates-text-color: var(--color-blue-800);
  --dp-range-between-border-color: var(--color-neutral-100);
  --dp-input-background-color: var(--color-blue-200);

  .dp--clear-btn:hover {
    color: var(--color-black);
  }

  .dp__btn,
  .dp__calendar_item,
  .dp__action_button {
    &:hover {
      outline-color: var(--color-blue-600);
    }

    &:focus {
      outline-color: var(--color-blue-800);
    }
  }

  .dp__button,
  .dp__action_button {
    color: var(--color-gray-300);
    background: var(--color-green-200);
  }
}

:deep(.dp__theme_dark) {
  --dp-background-color: var(--color-gray-500);
  --dp-text-color: var(--color-white);
  --dp-hover-color: var(--color-blue-900);
  --dp-hover-text-color: var(--color-white);
  --dp-hover-icon-color: var(--color-blue-800);
  --dp-primary-color: var(--color-blue-800);
  --dp-primary-disabled-color: var(--color-blue-950);
  --dp-primary-text-color: var(--color-white);
  --dp-secondary-color: var(--color-neutral-500);
  --dp-border-color: transparent;
  --dp-menu-border-color: var(--color-gray-900);
  --dp-border-color-hover: transparent;
  --dp-disabled-color: transparent;
  --dp-disabled-color-text: var(--color-neutral-500);
  --dp-scroll-bar-background: var(--color-gray-900);
  --dp-scroll-bar-color: var(--color-gray-400);
  --dp-success-color: var(--color-green-500);
  --dp-success-color-disabled: var(--color-green-900);
  --dp-icon-color: var(--color-neutral-500);
  --dp-danger-color: var(--color-red-500);
  --dp-marker-color: var(--color-blue-700);
  --dp-tooltip-color: var(--color-gray-900);
  --dp-highlight-color: var(--color-blue-800);
  --dp-range-between-dates-background-color: var(--color-blue-950);
  --dp-range-between-dates-text-color: var(--color-blue-800);
  --dp-range-between-border-color: var(--color-gray-900);
  --dp-input-background-color: var(--color-gray-900);

  .dp--clear-btn:hover {
    color: var(--color-white);
  }

  .dp__btn,
  .dp__calendar_item,
  .dp__action_button {
    &:hover {
      outline-color: var(--color-blue-900);
    }

    &:focus {
      outline-color: var(--color-blue-800);
    }
  }

  .dp__button,
  .dp__action_button {
    color: var(--color-neutral-400);
    background: var(--color-gray-600);
  }
}

:deep(.dp__main) {
  --dp-font-family: var(--default-font-family);
  --dp-border-radius: 0.5rem;
  --dp-cell-border-radius: 0.375rem;
  --dp-button-height: 1.5rem;
  --dp-month-year-row-height: 1.75rem;
  --dp-month-year-row-button-size: 1.75rem;
  --dp-button-icon-height: 1rem;
  --dp-cell-size: 1.5rem;
  --dp-cell-padding: 0.5rem;
  --dp-common-padding: 0.5rem;
  --dp-input-icon-padding: 0.5rem;
  --dp-input-padding: var(--dp-common-padding);
  --dp-menu-min-width: 210px;
  --dp-action-buttons-padding: 0.75rem;
  --dp-row-margin: 0.5rem 0;
  --dp-calendar-header-cell-padding: 0.5rem;
  --dp-two-calendars-spacing: 10px;
  --dp-overlay-col-padding: 0.5rem;
  --dp-time-inc-dec-button-size: 1.75rem;
  --dp-menu-padding: 0.5rem;
  --dp-font-size: 0.875rem;
  --dp-preview-font-size: 0.75rem;
  --dp-time-font-size: 1rem;

  .dp__input_icon {
    left: unset;
    right: 0.625rem;

    &:where([dir='rtl'], [dir='rtl'] *) {
      left: 2.5rem;
      right: unset;
    }
  }

  .dp__input_icon_pad {
    padding-inline-start: var(--dp-common-padding);
    padding-inline-end: var(--dp-input-icon-padding);
  }

  .dp__input_wrap {
    display: flex;
  }

  .dp--clear-btn {
    right: 1.5rem;

    &:where([dir='rtl'], [dir='rtl'] *) {
      left: 1.5rem;
      right: unset;
    }
  }

  .dp--tp-wrap {
    padding: var(--dp-common-padding);
    max-width: none;
  }

  .dp__inner_nav:hover,
  .dp__month_year_select:hover,
  .dp__year_select:hover,
  .dp__date_hover:hover,
  .dp__inc_dec_button {
    background: transparent;
    transition: none;
  }

  .dp__date_hover.dp__cell_offset:hover {
    color: var(--dp-secondary-color);
  }

  .dp__menu_inner {
    padding-bottom: 0;
  }

  .dp__action_row {
    padding-top: 0;
    margin-top: 0.125rem;
  }

  .dp__btn,
  .dp__button,
  .dp__calendar_item,
  .dp__action_button {
    transition: none;
    border-radius: 0.375rem;
    outline-color: transparent;

    &:hover {
      outline-width: 1px;
      outline-style: solid;
      outline-offset: 1px;
    }

    &:focus {
      outline-width: 1px;
      outline-style: solid;
      outline-offset: 1px;
    }
  }

  .dp__calendar_row {
    gap: 0.375rem;
  }

  .dp__month_year_wrap {
    gap: 0.5rem;
  }

  .dp__time_col {
    gap: 0.75rem;
  }

  .dp__today {
    border: none;
    color: var(--color-blue-800);

    &.dp__range_start,
    &.dp__range_end,
    &.dp__active_date {
      color: var(--color-white);
    }
  }

  .dp__action_buttons {
    margin-inline-start: 0;
    flex-grow: 1;
  }

  .dp__action_button {
    margin-inline-start: 0;
    transition: none;
    flex-grow: 1;
    display: inline-flex;
    justify-content: center;
    border-radius: 0.375rem;
  }

  .dp__action_cancel {
    border: 0;
  }

  .dp--arrow-btn-nav .dp__inner_nav {
    color: var(--color-blue-800);
  }

  /* NB: Fix orientation of the popover arrow in RTL locales. */

  .dp__arrow_top:where([dir='rtl'], [dir='rtl'] *) {
    transform: translate(-50%, -50%) rotate(-45deg);
  }

  .dp__arrow_bottom:where([dir='rtl'], [dir='rtl'] *) {
    transform: translate(-50%, 50%) rotate(45deg);
  }

  .dp__overlay_container {
    padding-bottom: 0.5rem;
  }

  .dp__overlay_container + .dp__button,
  .dp__overlay_row + .dp__button {
    width: auto;
    margin: 0.5rem;
  }

  .dp__overlay_container + .dp__button {
    width: calc(var(--dp-menu-min-width));
  }

  .dp__time_display {
    transition: none;
    padding: 0.5rem;
  }

  .dp__range_start,
  .dp__range_end,
  .dp__range_between {
    transition: none;
    border: none;
    border-radius: 0.375rem;
  }

  .dp__range_between:hover {
    background: var(--dp-range-between-dates-background-color);
    color: var(--dp-range-between-dates-text-color);
  }

  .dp__range_end,
  .dp__range_start,
  .dp__active_date {
    &.dp__cell_offset {
      color: var(--dp-primary-text-color);
    }
  }

  .dp__calendar_header {
    font-weight: 400;
    text-transform: uppercase;
  }
}
</style>
