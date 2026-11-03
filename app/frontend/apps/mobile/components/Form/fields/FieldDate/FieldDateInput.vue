<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside } from '@vueuse/core'
import { format } from 'date-fns'
import { computed, nextTick, toRef, useTemplateRef } from 'vue'

import {
  buildFormatParts,
  toDateFnsFormat,
} from '#shared/components/Form/fields/FieldDate/dateFormat.ts'
import type { DateFieldContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { useDateFieldValue } from '#shared/components/Form/fields/FieldDate/useDateFieldValue.ts'
import { useDatePanel } from '#shared/components/Form/fields/FieldDate/useDatePanel.ts'
import stopEvent from '#shared/utils/events.ts'

import FieldDatePanel from './FieldDatePanel.vue'

interface Props {
  context: DateFieldContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const {
  bounds,
  clearValue,
  commit,
  dateFnsLocale,
  hasValue,
  is24,
  localeFormat,
  refreshNow,
  selectedDate,
  showWeekNumbers,
  timePicker,
} = useDateFieldValue(contextReactive)

// Nothing is typed on mobile, so the value is only ever shown in the locale's format.
const displayValue = computed(() => {
  if (!selectedDate.value) return ''

  return format(selectedDate.value, toDateFnsFormat(buildFormatParts(localeFormat.value)))
})

const inputElement = useTemplateRef<HTMLInputElement>('input')
const wrapperElement = useTemplateRef('wrapper')

const panelId = computed(() => `${contextReactive.value.id}-panel`)

const { close, isOpen, open } = useDatePanel({
  input: inputElement,
  disabled: () => Boolean(contextReactive.value.disabled),
  onOpen: refreshNow,
})

const toggle = () => {
  if (isOpen.value) close()
  else open()
}

onClickOutside(wrapperElement, () => close())

const onInputKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    if (!isOpen.value) return
    stopEvent(event)
    close()
    return
  }

  if (event.key === 'Enter' || event.key === ' ' || (event.key === 'ArrowDown' && event.altKey)) {
    stopEvent(event)
    toggle()
  }
}

const onPanelKeydown = (event: KeyboardEvent) => {
  if (event.key !== 'Escape') return

  stopEvent(event)
  close({ refocus: true })
}

// The control goes with the value it clears, so the focus moves on to the field itself.
const clear = () => {
  clearValue()
  nextTick(() => inputElement.value?.focus())
}
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <div ref="wrapper" class="flex w-full flex-col" data-test-id="field-date">
    <div class="relative flex w-full">
      <input
        :id="context.id"
        ref="input"
        :name="context.node.name"
        :class="context.classes.input"
        :value="displayValue"
        type="text"
        readonly
        inputmode="none"
        autocomplete="off"
        :disabled="context.disabled"
        :aria-describedby="context.describedBy"
        aria-haspopup="dialog"
        :aria-controls="isOpen ? panelId : undefined"
        v-bind="context.attrs"
        @click="toggle()"
        @keydown="onInputKeydown"
        @blur="context.handlers.blur"
      />
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        class="absolute top-1/2 shrink-0 -translate-y-1/2 text-gray ltr:right-2 rtl:left-2"
        :aria-label="$t('Clear the value')"
        name="close-small"
        size="base"
        role="button"
        tabindex="0"
        @click.stop="clear()"
        @keydown.enter.prevent="clear()"
        @keydown.space.prevent="clear()"
      />
    </div>
    <div
      v-if="isOpen"
      :id="panelId"
      role="dialog"
      :aria-label="$t('Choose date')"
      class="w-full"
      :class="{ 'pe-2': context.link }"
      data-test-id="field-date-panel"
      @keydown="onPanelKeydown"
    >
      <div class="h-px w-full bg-white/10" />
      <FieldDatePanel
        :selected="selectedDate"
        :bounds="bounds"
        :with-time="timePicker"
        :default-time="context.defaultTime"
        :week-start="context.weekStart ?? 1"
        :locale="dateFnsLocale"
        :is24="is24"
        :show-week-numbers="showWeekNumbers"
        @commit="commit"
        @done="close({ refocus: true })"
      />
    </div>
  </div>
</template>
