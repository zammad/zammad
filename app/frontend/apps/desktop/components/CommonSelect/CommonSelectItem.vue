<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import { computed } from 'vue'
import { i18n } from '#shared/i18n.ts'
import type {
  MatchedSelectOption,
  SelectOption,
} from '#shared/components/CommonSelect/types.ts'

const props = defineProps<{
  option: MatchedSelectOption | SelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
}>()

const emit = defineEmits<{
  (e: 'select', option: SelectOption): void
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
</script>

<template>
  <div
    :class="{
      'pointer-events-none': option.disabled,
    }"
    :tabindex="option.disabled ? '-1' : '0'"
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
      v-if="multiple"
      :class="{
        'fill-gray-100 group-hover:fill-black group-focus:fill-white dark:fill-neutral-400 dark:group-hover:fill-white':
          !option.disabled,
        'fill-stone-200 dark:fill-neutral-500': option.disabled,
      }"
      size="xs"
      decorative
      :name="selected ? 'check-square' : 'square'"
      class="shrink-0"
    />
    <CommonIcon
      v-if="option.icon"
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
      :title="label"
    >
      {{ label }}
    </span>
    <CommonIcon
      v-if="!multiple"
      class="shrink-0 fill-stone-200 group-hover:fill-black group-focus:fill-white dark:fill-neutral-500 dark:group-hover:fill-white"
      :class="{
        invisible: !selected,
        'fill-gray-100 dark:fill-neutral-400': option.disabled,
      }"
      decorative
      size="tiny"
      name="check2"
    />
  </div>
</template>
