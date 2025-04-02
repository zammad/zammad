<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { CellContentProps } from '../types.ts'

const props = defineProps<CellContentProps>()
</script>

<template>
  <CommonDateTime
    v-if="props.value"
    class="group-focus-visible:text-white"
    :class="{
      'text-black dark:text-white': isRowSelected,
    }"
    :date-time="props.value as string"
    type="absolute"
  />
</template>
