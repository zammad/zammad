<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'

interface Props {
  fallback: RouteLocationRaw
  label?: string
}

defineProps<Props>()
</script>

<template>
  <button
    class="flex cursor-pointer items-center"
    :class="{ 'gap-2': label }"
    @click="$walker.back(fallback)"
  >
    <CommonIcon name="arrow-left" size="small" />
    <span v-if="label">{{ $t(label) }}</span>
  </button>
</template>
