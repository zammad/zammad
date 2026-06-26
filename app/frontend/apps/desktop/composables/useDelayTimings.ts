// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'

interface DelayTimings {
  short: number
  veryShort: number
}

export const useDelayTimings = () => {
  const { hasReducedMotion } = useReducedMotion()

  const timings = computed<DelayTimings>(() =>
    hasReducedMotion.value
      ? {
          short: 0,
          veryShort: 0,
        }
      : {
          short: 200,
          veryShort: 100,
        },
  )

  return { timings }
}
