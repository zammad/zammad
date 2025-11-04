<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import type {
  FlatSelectOption,
  MatchedFlatSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

const props = defineProps<{
  option: FlatSelectOption | MatchedFlatSelectOption
  index: number
  total: number // total number of options
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
  noSelectionIndicator?: boolean
  hasTopButton?: boolean
  hasDirectionUp?: boolean
}>()

const emit = defineEmits<{
  select: [option: FlatSelectOption]
  next: [{ option: FlatSelectOption; noFocus?: boolean }]
}>()

const locale = useLocaleStore()

const select = (option: FlatSelectOption) => {
  if (props.option.disabled) return

  emit('select', option)
}

const label = computed(() => {
  const { option } = props

  if (props.noLabelTranslate) return option.label || option.value.toString()

  return i18n.t(option.label, ...(option.labelPlaceholder || [])) || option.value.toString()
})

const isLastItem = computed(() => props.index + 1 === props.total)
const isFirstItem = computed(() => props.index === 0)

const goToNextPage = (option: FlatSelectOption, noFocus?: boolean) => {
  emit('next', { option, noFocus })
}

const optionElement = useTemplateRef('option-button')

const handleClickOnNext = (option: FlatSelectOption | MatchedFlatSelectOption) => {
  if (option.disabled) return optionElement.value?.click()
  goToNextPage(option)
}

const handleNextPageOrSelect = () =>
  props.option.disabled ? goToNextPage(props.option, false) : select(props.option)
</script>

<template>
  <div
    role="option"
    :aria-selected="selected"
    class="flex group h-9 cursor-pointer items-center self-stretch text-sm text-black outline-hidden dark:text-white"
    :class="{
      'hover:bg-blue-800 has-focus-visible:shadow-[inset_0_0_0_1px_var(--color-blue-800)] ':
        option.disabled,
      'first:rounded-t-[7px]': !hasTopButton && hasDirectionUp,
    }"
  >
    <button
      ref="option-button"
      tabindex="0"
      data-type="option"
      data-test-id="option-button"
      class="size-full text-left flex items-center gap-1.5 rtl:pr-2.5 ltr:pl-2.5"
      :class="{
        'group/button hover:bg-blue-600 dark:hover:bg-blue-900 focus-visible-app-default -outline-offset-1!':
          !option.disabled,
        'hover:text-black  dark:hover:text-white outline-none': option.disabled,
        'rounded-tl-[7px]!': !hasTopButton && hasDirectionUp && isFirstItem,
        'rounded-bl-[7px]': !hasDirectionUp && isLastItem,
      }"
      :aria-description="option.disabled ? $t('This item expands to show more options') : undefined"
      :data-value="option.value"
      @click="handleNextPageOrSelect"
      @keydown.space.prevent="handleNextPageOrSelect"
      @keydown.enter.prevent="handleNextPageOrSelect"
    >
      <CommonIcon
        v-if="multiple && !noSelectionIndicator && !option.disabled"
        size="xs"
        decorative
        :name="selected ? 'check-square' : 'square'"
        class="m-0.5 shrink-0 fill-gray-100 group-hover/button:fill-black dark:fill-neutral-400 dark:group-hover/button:fill-white"
        :class="{ 'group-hover:fill-white': option.disabled }"
      />
      <CommonIcon
        v-else-if="!noSelectionIndicator"
        class="shrink-0 fill-gray-100 group-hover:fill-black dark:fill-neutral-400 dark:group-hover:fill-white"
        :class="{
          invisible: !selected,
          'group-hover:fill-white': option.disabled,
        }"
        decorative
        size="tiny"
        name="check2"
      />
      <CommonIcon
        v-if="option.icon"
        :name="option.icon"
        size="tiny"
        decorative
        class="shrink-0 fill-gray-100 group-hover/button:fill-black dark:fill-neutral-400 dark:group-hover:fill-white"
      />
      <!--      eslint-disable vue/no-v-html -->
      <span
        v-if="filter"
        v-tooltip="label"
        :class="{
          'pointer-events-none text-stone-200 dark:text-neutral-500': option.disabled,
        }"
        class="grow truncate dark:group-hover/button:text-white group-hover/button:text-black"
        v-html="(option as MatchedFlatSelectOption).matchedPath"
      />
      <span
        v-else
        v-tooltip="label"
        class="grow truncate dark:group-hover/button:text-white group-hover/button:text-black"
        :class="{ 'group-hover:text-white': option.disabled }"
      >
        {{ label }}
      </span>
    </button>
    <!--  eslint-disable vuejs-accessibility/no-static-element-interactions  -->
    <div
      v-if="option.hasChildren && !filter"
      class="group/next shrink-0 m-0.5 flex items-center justify-center gap-x-2.5 p-2.5 rounded-lg"
      :class="{
        'focus-visible-app-default -outline-offset-1! hover:bg-blue-800': !option.disabled,
        'rounded-tr-lg': !hasTopButton && isFirstItem && hasDirectionUp,
        'rounded-b-lg': index + 1 === total && !hasDirectionUp,
      }"
      :aria-label="$t('Has submenu')"
      :role="option.disabled ? 'presentation' : 'button'"
      :tabindex="option.disabled ? -1 : 0"
      @click="handleClickOnNext(option)"
      @keydown.enter.prevent="handleClickOnNext(option)"
      @keydown.space.prevent="handleClickOnNext(option)"
    >
      <CommonIcon
        class="shrink-0 fill-blue-800!"
        :class="{
          'group-hover:fill-white! ': option.disabled,
          'group-hover/next:fill-white!': !option.disabled,
        }"
        :name="locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'"
        size="xs"
        decorative
      />
    </div>
  </div>
</template>
