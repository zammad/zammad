// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { useAppUsageStore } from '../appUsage.ts'

const grantAccessToBetaFeedback = () => {
  mockApplicationConfig({
    ui_desktop_beta_switch: true,
  })
  mockUserCurrent({
    hasBetaUiSwitchAvailable: true,
  })

  localStorage.setItem('beta-ui-switch', 'true')
  localStorage.setItem('beta-ui-feedback-consent', 'true')
}

describe('useAppUsageStore - when tracking usage', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.useRealTimers()
    localStorage.clear()
  })

  it('should initialize with default values', () => {
    const store = useAppUsageStore()

    expect(store).toBeDefined()
    expect(store.triggeredMilestones).toEqual({
      '1h': false,
      '5h': false,
      '20h': false,
    })
    expect(store.totalAppUsageTime).toBe(0)
    expect(store.currentMilestoneKey).toBe(null)
    expect(store.shouldTriggerMilestoneDialog).toBe(false)
  })

  it('persists total usage counter', () => {
    useAppUsageStore()

    const milestonesKey = 'app-usage-total-time'

    const storedValue = localStorage.getItem(milestonesKey)

    expect(storedValue).toBeDefined()
  })

  describe('milestone tracking', () => {
    it('should persist milestones in localStorage', () => {
      useAppUsageStore()

      const milestonesKey = 'app-usage-milestones-trigger-history'

      const storedValue = localStorage.getItem(milestonesKey)

      expect(storedValue).toBeDefined()
    })

    it('should restore milestones from localStorage on initialization', () => {
      localStorage.setItem(
        'app-usage-milestones-trigger-history',
        JSON.stringify({
          '1h': true,
          '5h': false,
          '20h': false,
        }),
      )

      const store = useAppUsageStore()

      expect(store.triggeredMilestones).toEqual({
        '1h': true,
        '5h': false,
        '20h': false,
      })
    })

    it('should identify current milestone key at 1h milestone', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      expect(store.currentMilestoneKey).toBe(null)

      vi.advanceTimersByTime(60 * 60 * 1000)

      expect(store.currentMilestoneKey).toBe('1h')
    })

    it('should identify current milestone key at 5h milestone', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      vi.advanceTimersByTime(5 * 60 * 60 * 1000)

      expect(store.currentMilestoneKey).toBe('5h')
    })

    it('should identify current milestone key at 20h milestone', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      vi.advanceTimersByTime(20 * 60 * 60 * 1000)

      expect(store.currentMilestoneKey).toBe('20h')
    })

    it('should trigger milestone dialog when milestone is reached and not yet triggered', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      expect(store.shouldTriggerMilestoneDialog).toBe(false)

      vi.advanceTimersByTime(60 * 60 * 1000)

      expect(store.shouldTriggerMilestoneDialog).toBe(true)

      store.triggerMilestone('1h')

      expect(store.shouldTriggerMilestoneDialog).toBe(false)
    })

    it('should not trigger milestone dialog after it has been triggered', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      vi.advanceTimersByTime(60 * 60 * 1000)

      expect(store.shouldTriggerMilestoneDialog).toBe(true)

      store.triggerMilestone('1h')

      expect(store.shouldTriggerMilestoneDialog).toBe(false)
    })

    it('should track milestone trigger history', () => {
      grantAccessToBetaFeedback()

      const store = useAppUsageStore()

      expect(store.triggeredMilestones['1h']).toBe(false)
      expect(store.triggeredMilestones['5h']).toBe(false)

      store.triggerMilestone('1h')
      store.triggerMilestone('5h')

      expect(store.triggeredMilestones['1h']).toBe(true)
      expect(store.triggeredMilestones['5h']).toBe(true)
    })
  })
})
