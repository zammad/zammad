// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { usePreferredReducedMotion } from '@vueuse/core'
import { computed } from 'vue'

export const useReducedMotion = () => {
  const preferredMotion = usePreferredReducedMotion()

  const hasReducedMotion = computed(() => VITE_TEST_MODE || preferredMotion.value === 'reduce')

  const scrollBehavior = computed(() => (hasReducedMotion.value ? 'instant' : 'smooth'))

  return {
    hasReducedMotion,
    scrollBehavior,
  }
}
