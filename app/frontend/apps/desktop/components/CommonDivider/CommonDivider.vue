<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { DividerOrientation } from './types.ts'

interface Props {
  orientation?: DividerOrientation
  padding?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'horizontal',
})
</script>

<template>
  <div
    :class="{
      'w-full': props.orientation === 'horizontal',
      'h-full': props.orientation === 'vertical',
      'px-2.5': props.padding && props.orientation === 'horizontal',
      'py-2.5': props.padding && props.orientation === 'vertical',
    }"
  >
    <hr
      class="border-0 bg-neutral-100 dark:bg-gray-900"
      :class="{
        'h-px w-full': props.orientation === 'horizontal',
        'h-full w-px': props.orientation === 'vertical',
      }"
    />
  </div>
</template>
