<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'

interface Props {
  fallback: RouteLocationRaw
  label?: string
  // list of routes users shouldn't go back to
  // useful, if there is a possible infinite loop
  // ticket -> information -> ticket -> information -> ...
  ignore?: string[]
}

defineProps<Props>()
</script>

<template>
  <button
    class="flex cursor-pointer items-center"
    :aria-label="$t('Go back')"
    :class="{ 'gap-2': label }"
    @click="$walker.back(fallback, ignore)"
  >
    <CommonIcon decorative name="mobile-chevron-left" />
    <span v-if="label">{{ $t(label) }}</span>
  </button>
</template>
