<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import { computed } from 'vue'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import type {
  FlatSelectOption,
  MatchedFlatSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'

const props = defineProps<{
  option: FlatSelectOption | MatchedFlatSelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
}>()

const emit = defineEmits<{
  (e: 'select', option: FlatSelectOption): void
  (
    e: 'next',
    { option, noFocus }: { option: FlatSelectOption; noFocus?: boolean },
  ): void
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
      'hover:bg-blue-600 dark:hover:bg-blue-900 focus:bg-blue-800 dark:hover:focus:bg-blue-800 focus:text-white cursor-pointer':
        !option.disabled,
    }"
    :tabindex="option.disabled ? '-1' : '0'"
    :aria-selected="selected"
    :aria-disabled="option.disabled ? 'true' : undefined"
    class="group h-9 px-2.5 flex items-center self-stretch gap-1.5 text-sm text-black dark:text-white outline-none"
    role="option"
    :data-value="option.value"
    @click="select(option)"
    @keypress.space.prevent="select(option)"
    @keypress.enter.prevent="select(option)"
  >
    <CommonIcon
      v-if="multiple"
      :class="{
        'fill-gray-100 dark:fill-neutral-400 group-hover:fill-black dark:group-hover:fill-white group-focus:fill-white':
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
      class="shrink-0 fill-gray-100 dark:fill-neutral-400 group-hover:fill-black dark:group-hover:fill-white group-focus:fill-white"
    />
    <span
      v-if="filter"
      :class="{
        'text-stone-200 dark:text-neutral-500 pointer-events-none':
          option.disabled,
      }"
      class="grow truncate"
      :title="label"
      v-html="(option as MatchedFlatSelectOption).matchedPath"
    />
    <span
      v-else
      :class="{
        'text-stone-200 dark:text-neutral-500 pointer-events-none':
          option.disabled,
      }"
      :title="label"
      class="grow truncate"
    >
      {{ label }}
    </span>
    <CommonIcon
      v-if="!multiple"
      class="shrink-0 fill-stone-200 dark:fill-neutral-500 group-hover:fill-black dark:group-hover:fill-white group-focus:fill-white"
      :class="{
        invisible: !selected,
        'fill-gray-100 dark:fill-neutral-400': option.disabled,
      }"
      decorative
      size="tiny"
      name="check2"
    />
    <div
      v-if="option.hasChildren && !filter"
      class="group/nav shrink-0 p-2.5 -me-2 flex-nowrap items-center justify-center gap-x-2.5 rounded-[5px] hover:bg-blue-800 group-focus:hover:bg-blue-600 dark:group-focus:hover:bg-blue-900"
      :aria-label="$t('Has submenu')"
      role="button"
      tabindex="-1"
      @click.stop="goToNextPage(option, true)"
      @keypress.enter.prevent.stop="goToNextPage(option)"
      @keypress.space.prevent.stop="goToNextPage(option)"
    >
      <CommonIcon
        :class="{
          'group-hover:fill-black dark:group-hover:fill-white group-focus:group-hover/nav:!fill-black dark:group-focus:group-hover/nav:!fill-white group-focus:fill-white':
            !option.disabled,
        }"
        class="shrink-0 fill-stone-200 dark:fill-neutral-500 group-hover/nav:!fill-white"
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
