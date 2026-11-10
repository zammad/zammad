<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { FieldRatingProps } from './types.ts'

const MAX_RATING = 5

const props = defineProps<FieldRatingProps>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue<string>(contextReactive)

const rating = computed(() => Number(localValue.value) || 0)

const valueText = computed(() =>
  rating.value ? i18n.t('%s of %s stars', rating.value, MAX_RATING) : i18n.t('No rating'),
)

// A rating of 0 clears the field, as it is no valid rating.
const setRating = (newRating: number) => {
  if (contextReactive.value.disabled || rating.value === newRating) return

  localValue.value = newRating ? String(newRating) : ''
}

const hover = ref<number | null>(null)

const getIconNameFor = (star: number) => {
  if (hover.value !== null) return star <= hover.value ? 'star-fill' : 'star'
  return star <= rating.value ? 'star-fill' : 'star'
}

// Only an optional rating can be cleared again, a required one stays between 1 and 5 once set.
const minRating = computed(() => (contextReactive.value.state.required ? 1 : 0))

const decreaseRating = () => {
  if (rating.value <= minRating.value) return

  setRating(rating.value - 1)
}

const increaseRating = () => {
  setRating(Math.min(rating.value + 1, MAX_RATING))
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
  <!-- A spinbutton instead of a slider, as the latter requires a value even while no rating is set. -->
  <div
    :id="context.id"
    data-test-id="field-rating-input"
    class="inline-flex items-center rounded-2xl bg-blue-200 p-2 px-2.25 focus-visible:outline focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:bg-gray-700"
    role="spinbutton"
    tabindex="0"
    :aria-labelledby="context.label ? `label-${context.id}` : undefined"
    :aria-describedby="context.describedBy"
    aria-valuemin="1"
    :aria-valuemax="MAX_RATING"
    :aria-valuenow="rating || undefined"
    :aria-valuetext="valueText"
    :aria-required="context.state.required || undefined"
    :aria-invalid="context.state.invalid || undefined"
    :aria-disabled="context.disabled || undefined"
    v-bind="context.attrs"
    @blur="context.handlers.blur"
    @keydown.arrow-left.prevent="horizontalArrowKey('start')"
    @keydown.arrow-right.prevent="horizontalArrowKey('end')"
    @keydown.arrow-up.prevent="increaseRating()"
    @keydown.arrow-down.prevent="decreaseRating()"
    @keydown.home.prevent="setRating(1)"
    @keydown.end.prevent="setRating(MAX_RATING)"
  >
    <span v-for="star in MAX_RATING" :key="star" class="relative h-4 w-5.5">
      <CommonIcon
        class="absolute h-4 w-5.5 text-transparent"
        :class="{
          'animate-ping-once text-contrast!': star === rating,
          invisible: hover === null || hover !== star,
        }"
        name="star-fill"
        size="tiny"
        decorative
      />
      <!-- This rule is save to disable because the element below is not part of tab order, the parent is. -->
      <!-- eslint-disable vuejs-accessibility/mouse-events-have-key-events -->
      <CommonIcon
        class="relative h-4 w-5.5 cursor-pointer outline-0 formkit-disabled:opacity-50"
        :data-test-id="`field-rating-star-${star}`"
        :class="{
          'text-contrast': hover !== null ? star <= hover : star <= rating,
        }"
        :name="getIconNameFor(star)"
        size="tiny"
        decorative
        tabindex="-1"
        @mouseover="hover = star"
        @mouseleave="hover = null"
        @click="setRating(star)"
      />
      <!-- eslint-enable vuejs-accessibility/mouse-events-have-key-events -->
    </span>
  </div>
</template>
