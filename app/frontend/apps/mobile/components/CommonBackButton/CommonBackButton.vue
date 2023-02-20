<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import { useWalker } from '@shared/router/walker'

interface Props {
  fallback: RouteLocationRaw
  label?: string
  // list of routes users shouldn't go back to
  // useful, if there is a possible infinite loop
  // ticket -> information -> ticket -> information -> ...
  ignore?: string[]
}

const props = defineProps<Props>()

const walker = useWalker()

const isHomeButton = computed(() => {
  if (props.fallback !== '/' || walker.hasBackUrl) return false
  return true
})
</script>

<template>
  <button
    class="flex cursor-pointer items-center"
    :aria-label="isHomeButton ? $t('Go home') : $t('Go back')"
    :class="{ 'gap-2': label }"
    @click="$walker.back(fallback, ignore)"
  >
    <CommonIcon
      :name="isHomeButton ? 'mobile-home' : 'mobile-chevron-left'"
      decorative
    />
    <span v-if="label">{{ isHomeButton ? $t('Home') : $t(label) }}</span>
  </button>
</template>
