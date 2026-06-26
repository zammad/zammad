// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useDelayTimings } from '../useDelayTimings.ts'

const hasReducedMotion = ref(false)

vi.mock('#shared/composables/useReducedMotion.ts', () => ({
  useReducedMotion: () => ({ hasReducedMotion }),
}))

describe('useDelayTimings', () => {
  afterEach(() => {
    hasReducedMotion.value = false
  })

  it('returns actual values for timings without reduced motion', () => {
    const { timings } = useDelayTimings()

    expect(timings.value.short).toBe(200)
    expect(timings.value.veryShort).toBe(100)
  })

  it('returns 0 for timings with reduced motion', () => {
    hasReducedMotion.value = true

    const { timings } = useDelayTimings()

    expect(timings.value.short).toBe(0)
    expect(timings.value.veryShort).toBe(0)
  })
})
