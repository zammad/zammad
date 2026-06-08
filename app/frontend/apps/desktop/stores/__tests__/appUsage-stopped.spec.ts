// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useAppUsageStore } from '../appUsage.ts'

//  INFO: There seems to be an issue with timer when they run in the same test file.
//        Some tests seems to be affected by previously defined timers even when
//        all mocks are cleared and real timers are restored.
//        To avoid this issue the tests related to "not tracking" usage are moved

describe('useAppUsageStore - when not to track usage', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.useRealTimers()
    localStorage.clear()
  })

  it('should not track usage when beta feedback consent is not given', async () => {
    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
    mockUserCurrent({
      hasBetaUiSwitchAvailable: true,
    })

    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'false') // ✅

    const store = useAppUsageStore()

    vi.advanceTimersByTime(60 * 60 * 1000)
    vi.runAllTimers()

    expect(store.totalAppUsageTime).toBe(0)

    localStorage.setItem('beta-ui-feedback-consent', 'null') // ✅

    await waitForNextTick()

    vi.advanceTimersByTime(60 * 60 * 1000)
    vi.runAllTimers()

    expect(store.totalAppUsageTime).toBe(0)
  })

  it('should not track usage when user is not granted for beta ui', () => {
    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
    mockUserCurrent({
      hasBetaUiSwitchAvailable: false, // ✅
    })

    localStorage.setItem('beta-ui-feedback-consent', 'null')

    const store = useAppUsageStore()

    vi.advanceTimersByTime(60 * 60 * 1000)
    vi.runAllTimers()

    expect(store.totalAppUsageTime).toBe(0)
  })

  it('should not track user when beta ui switch is disabled', () => {
    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
    mockUserCurrent({
      hasBetaUiSwitchAvailable: true,
    })

    localStorage.setItem('beta-ui-switch', 'false')

    const store = useAppUsageStore()

    vi.advanceTimersByTime(60 * 60 * 1000)
    vi.runAllTimers()

    expect(store.totalAppUsageTime).toBe(0)
  })
})
