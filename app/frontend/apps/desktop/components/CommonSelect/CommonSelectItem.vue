<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import { computed, type ConcreteComponent } from 'vue'

import type {
  MatchedSelectOption,
  SelectOption,
} from '#shared/components/CommonSelect/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types'
import { i18n } from '#shared/i18n.ts'

const props = defineProps<{
  option: MatchedSelectOption | SelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
  optionIconComponent?: ConcreteComponent
  noSelectionIndicator?: boolean
}>()

const emit = defineEmits<{
  select: [option: SelectOption]
}>()

const select = (option: SelectOption) => {
  if (props.option.disabled) {
    return
  }
  emit('select', option)
}

const label = computed(() => {
  const { option } = props

  if (props.noLabelTranslate) return option.label || option.value.toString()

  return (
    i18n.t(option.label, ...(option.labelPlaceholder || [])) ||
    option.value.toString()
  )
})

const heading = computed(() => {
  const { option } = props

  if (props.noLabelTranslate) return (option as AutoCompleteOption).heading

  return i18n.t(
    (option as AutoCompleteOption).heading,
    ...((option as AutoCompleteOption).headingPlaceholder || []),
  )
})

const OptionIconComponent = props.optionIconComponent
</script>

<template>
  <div
    :class="{
      'pointer-events-none': option.disabled,
    }"
    tabindex="0"
    :aria-selected="selected"
    :aria-disabled="option.disabled ? 'true' : undefined"
    class="group flex h-9 cursor-pointer items-center gap-1.5 self-stretch px-2.5 text-sm text-black outline-none hover:bg-blue-600 focus:bg-blue-800 focus:text-white hover:focus:focus:bg-blue-800 dark:text-white dark:hover:bg-blue-900"
    role="option"
    :data-value="option.value"
    @click="select(option)"
    @keypress.space.prevent="select(option)"
    @keypress.enter.prevent="select(option)"
  >
    <CommonIcon
      v-if="multiple && !noSelectionIndicator"
      :class="{
        'fill-gray-100 group-hover:fill-black group-focus:fill-white dark:fill-neutral-400 dark:group-hover:fill-white':
          !option.disabled,
        'fill-stone-200 dark:fill-neutral-500': option.disabled,
      }"
      size="xs"
      decorative
      :name="selected ? 'check-square' : 'square'"
      class="m-0.5 shrink-0"
    />
    <CommonIcon
      v-else-if="!noSelectionIndicator"
      class="shrink-0 fill-gray-100 group-hover:fill-black group-focus:fill-white dark:fill-neutral-400 dark:group-hover:fill-white"
      :class="{
        invisible: !selected,
        'fill-stone-200 dark:fill-neutral-500': option.disabled,
      }"
      decorative
      size="tiny"
      name="check2"
    />
    <OptionIconComponent v-if="optionIconComponent" :option="option" />
    <CommonIcon
      v-else-if="option.icon"
      :name="option.icon"
      size="tiny"
      :class="{
        'fill-stone-200 dark:fill-neutral-500': option.disabled,
      }"
      decorative
      class="shrink-0 fill-gray-100 group-hover:fill-black group-focus:fill-white dark:fill-neutral-400 dark:group-hover:fill-white"
    />
    <span
      v-if="filter"
      :class="{
        'text-stone-200 dark:text-neutral-500': option.disabled,
      }"
      class="grow truncate"
      :title="label"
      v-html="(option as MatchedSelectOption).matchedLabel"
    />
    <span
      v-else
      :class="{
        'text-stone-200 dark:text-neutral-500': option.disabled,
      }"
      class="grow truncate"
      :title="label + (heading ? ` – ${heading}` : '')"
    >
      {{ label }}
      <span v-if="heading" class="text-stone-200 dark:text-neutral-500"
        >– {{ heading }}</span
      >
    </span>
  </div>
</template>
