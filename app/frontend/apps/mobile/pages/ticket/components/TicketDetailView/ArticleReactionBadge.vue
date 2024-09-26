<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  reaction: string
}

defineProps<Props>()
</script>

<template>
  <div
    class="flex h-7 cursor-default items-center justify-center rounded-md px-1.5"
  >
    {{ reaction }}
  </div>
</template>
