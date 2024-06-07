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
import { useLocaleStore } from '#shared/stores/locale.ts'

const props = defineProps<{
  option: AutoCompleteOption | MatchedSelectOption | SelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
  optionIconComponent?: ConcreteComponent
  noSelectionIndicator?: boolean
}>()

const emit = defineEmits<{
  select: [option: SelectOption]
  next: [{ option: AutoCompleteOption; noFocus?: boolean }]
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

const locale = useLocaleStore()

const goToNextPage = (option: AutoCompleteOption, noFocus?: boolean) => {
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
    <div
      v-if="filter"
      class="grow truncate"
      :title="label + (heading ? ` – ${heading}` : '')"
    >
      <span
        :class="{
          'text-stone-200 dark:text-neutral-500':
            option.disabled && !(option as AutoCompleteOption).children?.length,
          'text-stone-100 dark:text-neutral-400':
            option.disabled && (option as AutoCompleteOption).children?.length,
        }"
        v-html="(option as MatchedSelectOption).matchedLabel"
      />
      <span v-if="heading" class="text-stone-200 dark:text-neutral-500"
        >&nbsp;– {{ heading }}</span
      >
    </div>
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
    <div
      v-if="(option as AutoCompleteOption).children?.length"
      class="group/nav -me-2 shrink-0 flex-nowrap items-center justify-center gap-x-2.5 rounded-[5px] p-2.5 hover:bg-blue-800 group-focus:hover:bg-blue-600 dark:group-focus:hover:bg-blue-900"
      :aria-label="$t('Has submenu')"
      role="button"
      tabindex="-1"
      @click.stop="goToNextPage(option as AutoCompleteOption, true)"
      @keypress.enter.prevent.stop="goToNextPage(option as AutoCompleteOption)"
      @keypress.space.prevent.stop="goToNextPage(option as AutoCompleteOption)"
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
