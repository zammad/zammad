// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useIdle, useIntervalFn } from '@vueuse/core'
import { computed, onScopeDispose, watch } from 'vue'

import type { TimeTrackerOptions } from '#desktop/types/appUsage.ts'

const TICK_TIME_MS = 30 * 1000 // Update interval: 30 seconds in milliseconds
const IDLE_TIME_OUT_MS = 5 * 60 * 1000 // 5 minutes in milliseconds

export const useTimeTracker = (
  tickCallback: (time: number) => void,
  options: TimeTrackerOptions = {},
) => {
  const { tickTime = TICK_TIME_MS, enabled = () => true } = options

  const { idle } = useIdle(IDLE_TIME_OUT_MS)

  const isActive = computed(() => !idle.value)
  const runTimer = computed(enabled)

  const { resume, pause } = useIntervalFn(
    () => {
      tickCallback(tickTime)
    },
    tickTime,
    { immediate: false },
  )

  watch(
    [isActive, runTimer],
    ([active, run]) => {
      return active && run ? resume() : pause()
    },
    { immediate: true },
  )

  onScopeDispose(pause)

  return { resume, pause }
}
