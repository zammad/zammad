<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import { computed } from 'vue'

import type {
  FlatSelectOption,
  MatchedFlatSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

const props = defineProps<{
  option: FlatSelectOption | MatchedFlatSelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
  noSelectionIndicator?: boolean
}>()

const emit = defineEmits<{
  select: [option: FlatSelectOption]
  next: [{ option: FlatSelectOption; noFocus?: boolean }]
}>()

const locale = useLocaleStore()

const select = (option: FlatSelectOption) => {
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

const goToNextPage = (option: FlatSelectOption, noFocus?: boolean) => {
  emit('next', { option, noFocus })
}
</script>

<template>
  <div
    :class="{
      'cursor-pointer hover:bg-blue-600 focus:bg-blue-800 focus:text-white dark:hover:bg-blue-900 dark:hover:focus:bg-blue-800':
        !option.disabled,
    }"
    tabindex="0"
    :aria-selected="selected"
    :aria-disabled="option.disabled ? 'true' : undefined"
    class="group flex h-9 cursor-default items-center gap-1.5 self-stretch px-2.5 text-sm text-black outline-none dark:text-white"
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
        'pointer-events-none text-stone-200 dark:text-neutral-500':
          option.disabled,
      }"
      class="grow truncate"
      :title="label"
      v-html="(option as MatchedFlatSelectOption).matchedPath"
    />
    <span
      v-else
      :class="{
        'pointer-events-none text-stone-200 dark:text-neutral-500':
          option.disabled && !option.hasChildren,
        'pointer-events-none text-gray-100 dark:text-neutral-400':
          option.disabled && option.hasChildren,
      }"
      :title="label"
      class="grow truncate"
    >
      {{ label }}
    </span>
    <div
      v-if="option.hasChildren && !filter"
      class="group/nav -me-2 shrink-0 flex-nowrap items-center justify-center gap-x-2.5 rounded-[5px] p-2.5 hover:bg-blue-800 group-focus:hover:bg-blue-600 dark:group-focus:hover:bg-blue-900"
      :aria-label="$t('Has submenu')"
      role="button"
      tabindex="-1"
      @click.stop="goToNextPage(option, true)"
      @keypress.enter.prevent.stop="goToNextPage(option)"
      @keypress.space.prevent.stop="goToNextPage(option)"
    >
      <CommonIcon
        :class="{
          'group-hover:fill-black group-focus:fill-white group-focus:group-hover/nav:!fill-black dark:group-hover:fill-white dark:group-focus:group-hover/nav:!fill-white':
            !option.disabled,
        }"
        class="shrink-0 fill-stone-200 group-hover/nav:!fill-white dark:fill-neutral-500"
        :name="
          locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'
        "
        size="xs"
        tabindex="-1"
        decorative
      />
    </div>
  </div>
</template>
