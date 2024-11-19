<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EventActionOutput } from '../types.ts'

interface Props {
  event: EventActionOutput
}

const { event } = defineProps<Props>()
</script>

<template>
  <span>
    <CommonLabel
      v-if="event.description"
      class="text-gray-100 dark:text-neutral-400"
      >{{ $t(event.description) }}</CommonLabel
    >
  </span>
</template>
