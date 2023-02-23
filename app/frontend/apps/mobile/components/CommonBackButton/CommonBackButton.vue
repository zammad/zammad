<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import { useLocaleStore } from '@shared/stores/locale'
import { useWalker } from '@shared/router/walker'

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
  if (props.avoidHomeButton || walker.getBackUrl(props.fallback) !== '/')
    return false
  return true
})

const { localeData } = useLocaleStore()

const icon = computed(() => {
  if (isHomeButton.value) return 'mobile-home'
  if (localeData?.dir === 'rtl') return 'mobile-chevron-right'
  return 'mobile-chevron-left'
})
</script>

<template>
  <button
    class="flex cursor-pointer items-center"
    :aria-label="isHomeButton ? $t('Go home') : $t('Go back')"
    :class="{ 'gap-2': label }"
    @click="$walker.back(fallback, ignore)"
  >
    <CommonIcon :name="icon" decorative />
    <span v-if="label">{{ isHomeButton ? $t('Home') : $t(label) }}</span>
  </button>
</template>
