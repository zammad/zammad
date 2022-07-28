<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  label?: string
  body?: string | number
}

defineProps<Props>()
</script>

<template>
  <div class="border-b border-gray-300 last:border-0">
    <div
      :title="$t(label)"
      class="min-h-[54px] border-b border-gray-300 py-3 last:border-0"
    >
      <div class="text-xs text-white/80">{{ $t(label) }}</div>
      <slot>{{ body }}</slot>
    </div>
  </div>
</template>
