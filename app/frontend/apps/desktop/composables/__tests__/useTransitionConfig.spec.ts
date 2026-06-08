// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTransitionConfig } from '../useTransitionConfig.ts'

describe('useTransitionConfig', () => {
  it('sets transition time to undefined in test environment', () => {
    const { durations } = useTransitionConfig()

    expect(durations.normal?.enter).toBe(300)
    expect(durations.normal?.leave).toBe(200)
  })

  it('returns 0 for short and veryShort timings in test environment', () => {
    const { timings } = useTransitionConfig()

    expect(timings.short).toBe(200)
    expect(timings.veryShort).toBe(100)
  })
})
