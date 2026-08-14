<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { VueDatePicker, WeekStart } from '@vuepic/vue-datepicker'
import { useEventListener } from '@vueuse/core'
import { computed, nextTick, ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { DateTimeContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { useDateFnsLocale } from '#shared/components/Form/fields/FieldDate/useDateFnsLocale.ts'
import { useDateTime } from '#shared/components/Form/fields/FieldDate/useDateTime.ts'
import { usePickerModel } from '#shared/components/Form/fields/FieldDate/usePickerModel.ts'
import {
  dateToJalali,
  jalaliToDate,
  jalaliMonthName,
  JALALI_WEEKDAY_SHORT,
  toPersianDigits,
} from '#shared/components/Form/fields/FieldDate/jalali.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import testFlags from '#shared/utils/testFlags.ts'

import '@vuepic/vue-datepicker/dist/main.css'

interface Props {
  context: DateTimeContext
}

const props = defineProps<Props>()

const { dateFnsLocale } = useDateFnsLocale()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue(contextReactive)

const { ariaLabels, displayFormat, is24, maxDate, minDate, timePicker, valueFormat } =
  useDateTime(contextReactive)

const { pickerModel } = usePickerModel(contextReactive, localValue)

// ── Jalali support ────────────────────────────────────────────────────────────

const localeStore = useLocaleStore()
const isJalaliLocale = computed(() => localeStore.localeData?.locale === 'fa-ir')
const weekStart = computed(() => (isJalaliLocale.value ? WeekStart.Saturday : WeekStart.Monday))

const navigateJalaliMonth = (
  month: number,
  year: number,
  isNext: boolean,
  updateMonthYear: (m: number, y: number) => void,
) => {
  const midDate = new Date(year, month, 15)
  const { jy, jm } = dateToJalali(midDate)
  let nextJy = jy
  let nextJm = jm + (isNext ? 1 : -1)
  if (nextJm > 12) {
    nextJm = 1
    nextJy++
  }
  if (nextJm < 1) {
    nextJm = 12
    nextJy--
  }
  const targetDate = jalaliToDate(nextJy, nextJm, 1)
  updateMonthYear(targetDate.getMonth(), targetDate.getFullYear())
}

const getJalaliMonthYearLabel = (month: number, year: number): string => {
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const { jy: jy1, jm: jm1 } = dateToJalali(firstDay)
  const { jy: jy2, jm: jm2 } = dateToJalali(lastDay)
  if (jm1 === jm2 && jy1 === jy2) {
    return `${jalaliMonthName(jm1)} ${toPersianDigits(jy1)}`
  }
  const yearSuffix = jy1 !== jy2 ? ` ${toPersianDigits(jy2)}` : ''
  return `${jalaliMonthName(jm1)} / ${jalaliMonthName(jm2)}${yearSuffix} ${toPersianDigits(jy1)}`
}

// ── Picker visibility ─────────────────────────────────────────────────────────

const config = {
  keepActionRow: true,
  monthChangeOnScroll: false,
}

const rangeConfig = computed(() => {
  if (!props.context.range) return false
  return {
    partialRange: false,
    ...(typeof props.context.range === 'object' ? props.context.range : {}),
  }
})

const actionRow = {
  showSelect: false,
  showCancel: false,
  showNow: true,
  showPreview: false,
  nowBtnLabel: i18n.t('Today'),
}

const input = ref<HTMLInputElement>()
const picker = ref()

const showPicker = ref(false)

const pickerDisplayStyle = computed(() => (showPicker.value ? 'block' : 'none'))

const expandPicker = () => {
  showPicker.value = true

  nextTick(() => {
    testFlags.set(`field-date-time-${props.context.id}.opened`)
  })
}

const collapsePicker = () => {
  showPicker.value = false

  nextTick(() => {
    testFlags.set(`field-date-time-${props.context.id}.closed`)
  })
}

useEventListener('click', (e) => {
  const { target } = e

  if (!target || !picker.value || !showPicker.value || !input.value) return

  const outer = (target as Element).closest('.formkit-outer')
  if (!outer) return

  const insideFormField = !outer.contains(target as Node)
  if (insideFormField) return

  collapsePicker()
})
</script>

<template>
  <div class="flex w-full">
    <!-- eslint-disable vuejs-accessibility/aria-props -->
    <VueDatePicker
      ref="picker"
      v-model="pickerModel"
      :class="{ 'pointer-events-none': context.disabled }"
      :model-type="valueFormat"
      :disabled="context.disabled"
      :range="rangeConfig"
      :partial-range="context.partialRange"
      :time-config="{
        enableTimePicker: timePicker,
        is24: is24,
        ignoreTimeValidation: !timePicker,
      }"
      :formats="displayFormat"
      :locale="dateFnsLocale"
      :max-date="maxDate"
      :min-date="minDate"
      :start-date="minDate || maxDate"
      :prevent-min-max-navigation="
        Boolean(minDate || maxDate || context.futureOnly || context.pastOnly)
      "
      :action-row="actionRow"
      :config="config"
      :aria-labels="ariaLabels"
      :inline="{ input: true }"
      :text-input="{ openMenu: 'toggle', format: displayFormat.input }"
      :input-attrs="{
        id: context.id,
        name: context.node.name,
        clearable: !!context.clearable,
      }"
      :week-start="weekStart"
      auto-apply
      dark
      @open="expandPicker"
      @close="collapsePicker"
      @blur="context.handlers.blur"
    >
      <!-- Jalali calendar header: weekday abbreviations (Sat…Fri) -->
      <template #calendar-header="{ day, index }">
        {{ isJalaliLocale ? JALALI_WEEKDAY_SHORT[index] : day }}
      </template>

      <!-- Jalali month/year header with Jalali-aware prev/next navigation -->
      <template
        #month-year="{ month, year, months, updateMonthYear, handleMonthYearChange, isDisabled }"
      >
        <div v-if="isJalaliLocale" class="dp--month-year-wrap">
          <button
            type="button"
            class="dp--btn dp--inner-nav dp--arrow-btn-nav"
            :disabled="isDisabled(true)"
            @click="navigateJalaliMonth(month, year, true, updateMonthYear)"
          >
            <CommonIcon name="chevron-left" size="xs" decorative />
          </button>
          <span class="dp--month-year-select font-medium">
            {{ getJalaliMonthYearLabel(month, year) }}
          </span>
          <button
            type="button"
            class="dp--btn dp--inner-nav dp--arrow-btn-nav"
            :disabled="isDisabled(false)"
            @click="navigateJalaliMonth(month, year, false, updateMonthYear)"
          >
            <CommonIcon name="chevron-right" size="xs" decorative />
          </button>
        </div>
        <div v-else class="dp--month-year-wrap">
          <button
            type="button"
            class="dp--btn dp--inner-nav dp--arrow-btn-nav"
            :disabled="isDisabled(false)"
            @click="handleMonthYearChange(false)"
          >
            <CommonIcon name="chevron-left" size="xs" decorative />
          </button>
          <button type="button" class="dp--btn dp--month-year-select">
            {{ months[month]?.text }}
          </button>
          <button type="button" class="dp--btn dp--year-select">
            {{ year }}
          </button>
          <button
            type="button"
            class="dp--btn dp--inner-nav dp--arrow-btn-nav"
            :disabled="isDisabled(true)"
            @click="handleMonthYearChange(true)"
          >
            <CommonIcon name="chevron-right" size="xs" decorative />
          </button>
        </div>
      </template>

      <!-- Jalali day numbers in each calendar cell -->
      <template #day="{ date, day }">
        <span v-if="isJalaliLocale">{{ toPersianDigits(dateToJalali(date).jd) }}</span>
        <span v-else>{{ day }}</span>
      </template>

      <template #dp-input="{ value, onInput, onEnter, onTab, onBlur, onKeypress, onPaste }">
        <input
          :id="context.id"
          ref="input"
          :value="value"
          :name="context.node.name"
          :class="context.classes.input"
          :aria-describedby="context.describedBy"
          :disabled="context.disabled"
          type="text"
          v-bind="context.attrs"
          @input="onInput"
          @keydown.enter="onEnter"
          @keydown.tab="onTab"
          @keydown="onKeypress"
          @paste="onPaste"
          @blur="onBlur"
          @focus="expandPicker"
        />
        <div v-if="showPicker" class="w-full" :class="{ 'pe-2': context.link }">
          <div class="h-px w-full bg-white/10" />
        </div>
      </template>
      <template #clear-icon>
        <CommonIcon
          class="absolute -mt-5 shrink-0 text-gray ltr:right-2 rtl:left-2"
          :aria-label="i18n.t('Clear selection')"
          name="close-small"
          size="base"
          role="button"
          tabindex="0"
          @click.stop="picker?.clearValue()"
          @keypress.space.prevent.stop="picker?.clearValue()"
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
:deep(.dp--outer-menu-wrap) .dp--menu {
  /* stylelint-disable value-keyword-case */
  display: v-bind(pickerDisplayStyle);
  max-width: var(--dp-menu-min-width);
  margin: 0 auto;
}

:deep(.dp--theme-dark) {
  --dp-background-color: var(--color-gray-500);
  --dp-text-color: var(--color-white);
  --dp-hover-color: transparent;
  --dp-hover-text-color: var(--color-white);
  --dp-hover-icon-color: var(--color-white);
  --dp-primary-color: var(--color-blue);
  --dp-secondary-color: var(--color-gray-200);
  --dp-border-color: transparent;
  --dp-menu-border-color: transparent;
  --dp-border-color-hover: transparent;
  --dp-range-between-dates-background-color: var(--color-blue-highlight);
  --dp-range-between-dates-text-color: var(--color-white);
  --dp-range-between-border-color: transparent;

  &:where([data-errors='true'] *),
  &:where([data-invalid='true'] *) {
    --dp-background-color: var(--color-red-dark);
  }
}

:deep(.dp--main) {
  --dp-font-family: var(--default-font-family);
  --dp-border-radius: 0.375rem;
  --dp-cell-border-radius: 9999px;
  --dp-button-height: 2rem;
  --dp-action-button-height: 2rem;
  --dp-month-year-row-height: 2rem;
  --dp-month-year-row-button-size: 2rem;
  --dp-common-padding: 0.5rem;
  --dp-action-row-padding: 0.5rem;
  --dp-menu-min-width: 260px;
  --dp-font-size: 1rem;
  --dp-preview-font-size: 1rem;
  --dp-time-font-size: 1.25rem;

  &,
  & > div {
    width: 100%;
  }

  .dp--button,
  .dp--action-button {
    border: none;
    color: var(--color-white);
    background: var(--color-gray-200);
  }

  .dp--clear-btn {
    top: 2.3rem;
  }

  .dp--tp-wrap {
    padding: var(--dp-common-padding);
    max-width: none;
  }

  .dp--btn,
  .dp--button,
  .dp--calendar-item,
  .dp--action-button {
    transition: none;
    border-radius: 0.375rem;
  }

  .dp--action-buttons {
    margin-inline-start: 0;
    flex-grow: 1;
  }

  .dp--action-button {
    margin-inline-start: 0;
    transition: none;
    flex-grow: 1;
    display: inline-flex;
    justify-content: center;
    border-radius: 0.375rem;
  }

  .dp--action-cancel {
    border: none;
  }

  .dp--arrow-btn-nav .dp--inner-nav {
    color: var(--color-blue);
  }

  .dp--overlay-container {
    padding-bottom: 0.5rem;
  }

  .dp--overlay-container + .dp--button,
  .dp--overlay-row + .dp--button {
    width: auto;
    margin: 0.5rem;
  }

  .dp--overlay-container + .dp--button:not(.dp--overlay-action) {
    width: calc(var(--dp-menu-min-width) - 0.375rem * 2);
  }

  .dp--overlay-container + .dp--button.dp--overlay-action {
    width: calc(var(--dp-menu-min-width) - 0.625rem * 2);
  }

  .dp--calendar-header-item {
    padding-left: 0;
    padding-right: 0;
  }
}
</style>
