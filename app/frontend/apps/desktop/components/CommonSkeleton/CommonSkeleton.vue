<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  rounded?: boolean
  label?: string
  alternativeBackground?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  label: __('Content loader'),
})

const roundedClass = computed(() => (props.rounded ? 'rounded-full' : 'rounded-md'))
const bgClass = computed(() =>
  props.alternativeBackground ? 'bg-blue-300 dark:bg-gray-700' : 'bg-blue-200 dark:bg-gray-700',
)
</script>

<template>
  <div
    tabindex="0"
    role="progressbar"
    aria-busy="true"
    aria-valuemin="0"
    aria-valuemax="100"
    :aria-label="$t(label)"
    :aria-valuetext="$t('Please wait until content is loaded')"
    :class="[
      roundedClass,
      bgClass,
      'animate-pulse focus:outline-none focus-visible:rounded-md focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 focus-visible:outline-none',
    ]"
  />
</template>
