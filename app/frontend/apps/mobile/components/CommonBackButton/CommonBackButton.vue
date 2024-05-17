<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useWalker } from '#shared/router/walker.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { RouteLocationRaw } from 'vue-router'

interface Props {
  fallback: RouteLocationRaw
  label?: string
  // list of routes users shouldn't go back to
  // useful, if there is a possible infinite loop
  // ticket -> information -> ticket -> information -> ...
  ignore?: string[]
  avoidHomeButton?: boolean
}

const props = defineProps<Props>()

const walker = useWalker()

const isHomeButton = computed(() => {
  return !(props.avoidHomeButton || walker.getBackUrl(props.fallback) !== '/')
})

const locale = useLocaleStore()

const icon = computed(() => {
  if (isHomeButton.value) return 'home'
  if (locale.localeData?.dir === 'rtl') return 'chevron-right'
  return 'chevron-left'
})
</script>

<template>
  <button
    class="flex cursor-pointer items-center"
    :aria-label="isHomeButton ? $t('Go home') : $t('Go back')"
    :class="{ 'gap-2': label }"
    type="button"
    @click="$walker.back(fallback, ignore)"
  >
    <CommonIcon :name="icon" decorative />
    <span v-if="label">{{ isHomeButton ? $t('Home') : $t(label) }}</span>
  </button>
</template>
