<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type ConcreteComponent } from 'vue'

import type { MatchedSelectOption, SelectOption } from '#shared/components/CommonSelect/types.ts'
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

const selectOrGoToNextPage = (option: SelectOption, focus?: boolean) =>
  props.option.disabled ? goToNextPage(option as AutoCompleteOption, focus) : emit('select', option)

const label = computed(() => {
  const { option } = props

  if (props.noLabelTranslate && !option.labelPlaceholder)
    return option.label || option.value.toString()

  return i18n.t(option.label, ...(option.labelPlaceholder || [])) || option.value.toString()
})

const heading = computed(() => {
  const { option } = props

  if (props.noLabelTranslate && !(option as AutoCompleteOption).headingPlaceholder)
    return (option as AutoCompleteOption).heading

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
      ' hover:bg-blue-600  dark:hover:bg-blue-900 ': !option.disabled,
      'hover:bg-blue-800': option.disabled,
    }"
    tabindex="0"
    :aria-selected="selected"
    :aria-description="option.disabled ? $t('This item expands to show more options') : undefined"
    class="group focus-visible:shadow-[inset_0_0_0_1px_var(--color-blue-800)] flex h-9 cursor-pointer items-center gap-1.5 self-stretch px-2.5 text-sm text-black outline-hidden dark:text-white"
    role="option"
    data-test-id="select-item"
    :data-value="option.value"
    @click="selectOrGoToNextPage(option, true)"
    @keypress.space.prevent="selectOrGoToNextPage(option)"
    @keypress.enter.prevent="selectOrGoToNextPage(option)"
  >
    <CommonIcon
      v-if="multiple && !noSelectionIndicator"
      :class="{
        'fill-gray-100 group-hover:fill-black dark:fill-neutral-400 dark:group-hover:fill-white':
          !option.disabled,
        'fill-stone-200 dark:fill-neutral-500 group-hover:fill-white': option.disabled,
      }"
      size="xs"
      decorative
      :name="selected ? 'check-square' : 'square'"
      class="m-0.5 shrink-0"
    />
    <CommonIcon
      v-else-if="!noSelectionIndicator"
      class="shrink-0 fill-gray-100 group-hover:fill-black dark:fill-neutral-400 dark:group-hover:fill-white"
      :class="{
        invisible: !selected,
        'fill-stone-200 dark:fill-neutral-500 group-hover:fill-white': option.disabled,
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
        'fill-stone-200 dark:fill-neutral-500 group-hover:fill-white': option.disabled,
      }"
      decorative
      class="shrink-0 fill-gray-100 group-hover:fill-black dark:fill-neutral-400 dark:group-hover:fill-white"
    />
    <div v-if="filter" v-tooltip="label + (heading ? ` – ${heading}` : '')" class="grow truncate">
      <!-- eslint-disable vue/no-v-html -->
      <span
        :class="{
          'text-stone-200 dark:text-neutral-500':
            option.disabled && !(option as AutoCompleteOption).children?.length,
          'text-gray-100 dark:text-neutral-400':
            option.disabled && (option as AutoCompleteOption).children?.length,
          'group-hover:text-white': option.disabled,
        }"
        v-html="(option as MatchedSelectOption).matchedLabel"
      />
      <span
        v-if="heading"
        class="text-stone-200 dark:text-neutral-500"
        :class="{
          'group-hover:text-black  group-hover:dark:text-white': !option.disabled,
          'group-hover:text-white': option.disabled,
        }"
        >&nbsp;– {{ heading }}</span
      >
    </div>
    <span
      v-else
      v-tooltip="label + (heading ? ` – ${heading}` : '')"
      :class="{
        'text-stone-200 dark:text-neutral-500 group-hover:text-white': option.disabled,
      }"
      class="grow truncate"
    >
      {{ label }}
      <span
        v-if="heading"
        class="text-stone-200 dark:text-neutral-500"
        :class="{
          'group-hover:text-black  group-hover:dark:text-white': !option.disabled,
          'group-hover:text-white': option.disabled,
        }"
        >– {{ heading }}</span
      >
    </span>
    <div
      v-if="(option as AutoCompleteOption).children?.length"
      class="group/nav -me-2 shrink-0 flex-nowrap items-center justify-center gap-x-2.5 rounded-[5px] p-2.5"
      :aria-label="$t('Has submenu')"
      role="presentation"
    >
      <CommonIcon
        class="shrink-0 fill-blue-800!"
        :class="{ 'group-hover:fill-white!': option.disabled }"
        :name="locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'"
        size="xs"
        decorative
      />
    </div>
  </div>
</template>
