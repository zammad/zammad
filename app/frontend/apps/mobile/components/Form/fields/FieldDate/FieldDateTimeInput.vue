<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import VueDatePicker from '@vuepic/vue-datepicker'
import { useEventListener } from '@vueuse/core'
import { computed, nextTick, ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { DateTimeContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { useDateTime } from '#shared/components/Form/fields/FieldDate/useDateTime.ts'
import { i18n } from '#shared/i18n.ts'
import testFlags from '#shared/utils/testFlags.ts'
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
  minDate,
  position,
  timePicker,
  valueFormat,
} = useDateTime(contextReactive)

const config = {
  keepActionRow: true,
}

const actionRow = {
  showSelect: false,
  showCancel: false,
  showNow: true,
  showPreview: false,
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
      :uid="context.id"
      :model-type="valueFormat"
      :name="context.node.name"
      :clearable="!!context.clearable"
      :disabled="context.disabled"
      :range="context.range"
      :enable-time-picker="timePicker"
      :format="displayFormat"
      :is-24="is24"
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
      :inline="{ input: true }"
      :month-change-on-scroll="false"
      :text-input="{ openMenu: 'toggle' }"
      auto-apply
      dark
      @open="expandPicker"
      @close="collapsePicker"
      @blur="context.handlers.blur"
    >
      <template
        #dp-input="{
          value,
          onInput,
          onEnter,
          onTab,
          onBlur,
          onKeypress,
          onPaste,
        }"
      >
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
          @keypress.enter="onEnter"
          @keypress.tab="onTab"
          @keypress="onKeypress"
          @paste="onPaste"
          @blur="onBlur"
          @focus="expandPicker"
        />
        <div v-if="showPicker" class="w-full" :class="{ 'pe-2': context.link }">
          <div class="h-[1px] w-full bg-white/10"></div>
        </div>
      </template>
      <template #clear-icon>
        <CommonIcon
          class="text-gray absolute -mt-5 shrink-0 ltr:right-2 rtl:left-2"
          :aria-label="i18n.t('Clear Selection')"
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
  --dp-background-color: theme(colors.gray.500);
  --dp-text-color: theme(colors.white);
  --dp-hover-color: theme(colors.transparent);
  --dp-hover-text-color: theme(colors.white);
  --dp-hover-icon-color: theme(colors.white);
  --dp-primary-color: theme(colors.blue.DEFAULT);
  --dp-secondary-color: theme(colors.gray.200);
  --dp-border-color: theme(colors.transparent);
  --dp-menu-border-color: theme(colors.transparent);
  --dp-border-color-hover: theme(colors.transparent);
  --dp-range-between-dates-background-color: theme(colors.blue.highlight);
  --dp-range-between-dates-text-color: theme(colors.white);
  --dp-range-between-border-color: theme(colors.transparent);

  &:where([data-errors='true'] *),
  &:where([data-invalid='true'] *) {
    --dp-background-color: theme(colors.red.dark);
  }
}

:deep(.dp__main) {
  --dp-font-family: theme(fontFamily.sans);
  --dp-border-radius: theme(borderRadius.md);
  --dp-cell-border-radius: theme(borderRadius.full);
  --dp-button-height: theme(size.8);
  --dp-action-button-height: theme(size.8);
  --dp-month-year-row-height: theme(size.8);
  --dp-month-year-row-button-size: theme(size.8);
  --dp-common-padding: theme(padding.2);
  --dp-action-row-padding: theme(padding.2);
  --dp-menu-min-width: 260px;
  --dp-font-size: theme(fontSize.base);
  --dp-preview-font-size: theme(fontSize.base);
  --dp-time-font-size: theme(fontSize.xl);

  & > div {
    width: 100%;
  }

  .dp {
    &__button,
    &__action_button {
      border: none;
      color: theme(colors.white);
      background: theme(colors.gray.200);
    }

    &--clear-btn {
      top: 2.3rem;
    }

    &--tp-wrap {
      padding: var(--dp-common-padding);
      max-width: none;
    }

    &__btn,
    &__button,
    &__calendar_item,
    &__action_button {
      transition: none;
      border-radius: theme(borderRadius.md);
    }

    &__action_buttons {
      margin-inline-start: 0;
      flex-grow: 1;
    }

    &__action_button {
      margin-inline-start: 0;
      transition: none;
      flex-grow: 1;
      display: inline-flex;
      justify-content: center;
      border-radius: theme(borderRadius.md);
    }

    &__action_cancel {
      border: none;
    }

    &--arrow-btn-nav .dp__inner_nav {
      color: theme(colors.blue.DEFAULT);
    }

    &__overlay_container {
      padding-bottom: theme(padding.2);
    }

    &__overlay_container + .dp__button,
    &__overlay_row + .dp__button {
      width: auto;
      margin: theme(margin.2);
    }

    &__overlay_container + .dp__button:not(.dp__overlay_action) {
      width: calc(var(--dp-menu-min-width) - theme(margin[1.5]) * 2);
    }

    &__overlay_container + .dp__button.dp__overlay_action {
      width: calc(var(--dp-menu-min-width) - theme(margin[2.5]) * 2);
    }
  }
}
</style>
