<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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

<style>
fieldset.column-1 > .formkit-outer {
  width: 100%;
}

fieldset.column-2 > .formkit-outer {
  width: 50%;
}

fieldset.column-2 > .formkit-outer:first-child {
  padding-right: 0.75rem;
}
</style>
