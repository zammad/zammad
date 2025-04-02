<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  rounded?: boolean
  label?: string
}

const props = withDefaults(defineProps<Props>(), {
  label: __('Content loader'),
})

const roundedClass = computed(() =>
  props.rounded ? 'rounded-full' : 'rounded-md',
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
    class="bg-primary animate-pulse bg-blue-200 focus:outline-none focus-visible:rounded-md focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 focus-visible:outline-none dark:bg-gray-700"
    :class="[roundedClass]"
  />
</template>
