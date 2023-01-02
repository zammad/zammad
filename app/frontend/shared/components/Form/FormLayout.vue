<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  columns?: number
}

const props = withDefaults(defineProps<Props>(), {
  columns: 1,
})

const columnClass = computed(() => {
  return `column-${props.columns}`
})
</script>

<template>
  <fieldset class="flex flex-wrap" :class="columnClass">
    <slot />
  </fieldset>
</template>

<style lang="postcss">
fieldset.column-1 > .formkit-outer {
  @apply w-full;
}

fieldset.column-2 > .formkit-outer {
  @apply w-1/2;
}

fieldset.column-2 > .formkit-outer:first-child {
  @apply pr-3;
}
</style>
