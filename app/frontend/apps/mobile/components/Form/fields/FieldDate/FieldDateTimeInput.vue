<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { VueDatePicker } from '@vuepic/vue-datepicker'
import { useEventListener } from '@vueuse/core'
import { computed, nextTick, ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { DateTimeContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { useDateFnsLocale } from '#shared/components/Form/fields/FieldDate/useDateFnsLocale.ts'
import { useDateTime } from '#shared/components/Form/fields/FieldDate/useDateTime.ts'
import { i18n } from '#shared/i18n.ts'
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

const config = {
  keepActionRow: true,
  monthChangeOnScroll: false,
}

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

// Hide calendar, if clicked outside of the picker or input.
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
      v-model="localValue"
      :class="{ 'pointer-events-none': context.disabled }"
      :model-type="valueFormat"
      :disabled="context.disabled"
      :range="context.range"
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
      auto-apply
      dark
      @open="expandPicker"
      @close="collapsePicker"
      @blur="context.handlers.blur"
    >
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
          class="text-gray absolute -mt-5 shrink-0 ltr:right-2 rtl:left-2"
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
:deep(.dp__outer_menu_wrap) .dp__menu {
  /* stylelint-disable value-keyword-case */
  display: v-bind(pickerDisplayStyle);
  max-width: var(--dp-menu-min-width);
  margin: 0 auto;
}

:deep(.dp__theme_dark) {
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
  --dp-range-between-dates-background-color: var('--color-blue-highlight');
  --dp-range-between-dates-text-color: var(--color-white);
  --dp-range-between-border-color: transparent;

  &:where([data-errors='true'] *),
  &:where([data-invalid='true'] *) {
    --dp-background-color: var(--color-red-dark);
  }
}

:deep(.dp__main) {
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

  & > div {
    width: 100%;
  }

  .dp__button,
  .dp__action_button {
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

  .dp__btn,
  .dp__button,
  .dp__calendar_item,
  .dp__action_button {
    transition: none;
    border-radius: 0.375rem;
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
    border: none;
  }

  .dp--arrow-btn-nav .dp__inner_nav {
    color: var(--color-blue);
  }

  .dp__overlay_container {
    padding-bottom: 0.5rem;
  }

  .dp__overlay_container + .dp__button,
  .dp__overlay_row + .dp__button {
    width: auto;
    margin: 0.5rem;
  }

  .dp__overlay_container + .dp__button:not(.dp__overlay_action) {
    width: calc(var(--dp-menu-min-width) - 0.375rem * 2);
  }

  .dp__overlay_container + .dp__button.dp__overlay_action {
    width: calc(var(--dp-menu-min-width) - 0.625rem * 2);
  }

  .dp__calendar_header_item {
    padding-left: 0;
    padding-right: 0;
  }
}
</style>
