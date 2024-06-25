// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useTransitionConfig } from '../useTransitionConfig.ts'

describe('useTransitionConfig', () => {
  it('sets transition time to undefined in test environment', () => {
    const { durations } = useTransitionConfig()

    expect(durations.normal?.enter).toBeFalsy()
    expect(durations.normal?.leave).toBeFalsy()
  })
})
