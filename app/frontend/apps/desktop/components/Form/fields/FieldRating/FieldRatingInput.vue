<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { FieldRatingProps } from './types.ts'

const props = defineProps<FieldRatingProps>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue<string>(contextReactive)

const selectRating = (star: number) => {
  const newRating = String(star)
  if (localValue.value === newRating) return

  localValue.value = newRating
}

const hover = ref<number | null>(null)

const getIconNameFor = (star: number) => {
  if (hover.value !== null) return star <= hover.value ? 'star-fill' : 'star'
  return star <= (Number(localValue.value) || 0) ? 'star-fill' : 'star'
}

const decreaseRating = () => {
  const newRating = Math.max((Number(localValue.value) || 0) - 1, 0)

  if (newRating > 0) {
    selectRating(newRating)
    return
  }

  if (!localValue.value) return

  localValue.value = ''
}

const increaseRating = () => {
  selectRating(Math.min((Number(localValue.value) || 0) + 1, 5))
}

const locale = useLocaleStore()

const localeData = toRef(locale, 'localeData')

const horizontalArrowKey = (direction?: 'start' | 'end') => {
  const isLtrLocale = localeData.value?.dir === EnumTextDirection.Ltr
  const shouldIncrease = direction === 'start' ? !isLtrLocale : isLtrLocale

  if (shouldIncrease) {
    increaseRating()
    return
  }

  decreaseRating()
}
</script>

<template>
  <!-- The outer div is focusable to allow keyboard navigation and control, and is hidden from screen readers. -->
  <div
    data-test-id="field-rating-input"
    class="inline-flex items-center rounded-2xl bg-blue-200 p-2 px-2.25 focus-visible:outline focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:bg-gray-700"
    tabindex="0"
    aria-hidden="true"
    v-bind="context.attrs"
    @blur="context.handlers.blur"
    @keydown.arrow-left.prevent="horizontalArrowKey('start')"
    @keydown.arrow-right.prevent="horizontalArrowKey('end')"
    @keydown.arrow-up.prevent="increaseRating()"
    @keydown.arrow-down.prevent="decreaseRating()"
  >
    <span v-for="star in 5" :key="star" class="relative h-4 w-5.5">
      <CommonIcon
        class="absolute h-4 w-5.5 text-transparent"
        :class="{
          'animate-ping-once text-black! dark:text-white!': star === (Number(localValue) || 0),
          invisible: hover === null || hover !== star,
        }"
        name="star-fill"
        size="tiny"
      />
      <!-- This rule is save to disable because the element below is not part of tab order, the parent is. -->
      <!-- eslint-disable vuejs-accessibility/mouse-events-have-key-events -->
      <CommonIcon
        class="relative h-4 w-5.5 cursor-pointer outline-0 formkit-disabled:opacity-50"
        :data-test-id="`field-rating-star-${star}`"
        :class="{
          'text-black dark:text-white':
            hover !== null ? star <= hover : star <= (Number(localValue) || 0),
        }"
        :name="getIconNameFor(star)"
        size="tiny"
        decorative
        tabindex="-1"
        @mouseover="hover = star"
        @mouseleave="hover = null"
        @click="selectRating(star)"
      />
      <!-- eslint-enable vuejs-accessibility/mouse-events-have-key-events -->
    </span>
  </div>
  <!-- The number input field is presented to screen readers only. -->
  <FormKit
    :id="context.id"
    v-model="localValue"
    outer-class="sr-only"
    tabindex="-1"
    type="number"
    min="1"
    max="5"
    :disabled="context.disabled"
    :ignore="true"
  />
</template>
