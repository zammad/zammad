// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { nextTick } from 'vue'

import { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import { useBetaUiFeedbackRouteGuard } from '#desktop/components/BetaUi/composables/useBetaUiFeedbackRouteGuard.ts'
import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

const beforeEachHook = vi.fn()
const openFeedbackDialog = vi.fn()

vi.mock('vue-router', async (originalModule) => {
  const module = await originalModule<typeof import('vue-router')>()

  return {
    ...module,
    useRouter: () => ({
      beforeEach: beforeEachHook,
    }),
  }
})

vi.mock('#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts', () => ({
  useFeedbackDialog: () => ({ openFeedbackDialog }),
}))

const setUsageHours = (hours: number) => {
  localStorage.setItem('app-usage-total-time', JSON.stringify(hours * 60 * 60 * 1000))
}

const resetMilestones = () => {
  localStorage.setItem(
    'app-usage-milestones-trigger-history',
    JSON.stringify({ '1h': false, '5h': false, '20h': false }),
  )
}

const setupStore = () => {
  initializePiniaStore()
  return useAppUsageStore()
}

const runGuard = () => {
  useBetaUiFeedbackRouteGuard()

  expect(beforeEachHook).toHaveBeenCalledTimes(1)

  const [hook] = beforeEachHook.mock.calls.at(0) ?? []
  return hook as (to: unknown, from: { name?: string }) => void
}

describe('Ui beta timed feedback', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    beforeEachHook.mockClear()
    openFeedbackDialog.mockClear()
    localStorage.clear()

    // Enable beta UI + consent so usage tracking is considered active
    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'true')

    resetMilestones()
  })

  it('opens feedback dialog and marks milestone when eligible navigation occurs', async () => {
    setUsageHours(1)
    const store = setupStore()
    const triggerSpy = vi.spyOn(store, 'triggerMilestone')

    const hook = runGuard()

    hook({}, { name: 'TicketDetailView' })

    await nextTick()

    expect(openFeedbackDialog).toHaveBeenCalledWith({ milestone: '1h' })
    expect(triggerSpy).toHaveBeenCalledWith('1h')
    expect(store.triggeredMilestones['1h']).toBe(true)
    expect(store.shouldTriggerMilestoneDialog).toBe(false)
  })

  it('ignores initial navigation without a from route', () => {
    setUsageHours(1)
    setupStore()

    const hook = runGuard()

    hook({}, { name: undefined })

    expect(openFeedbackDialog).not.toHaveBeenCalled()
  })

  it('ignores navigation coming from login', () => {
    setUsageHours(1)
    setupStore()

    const hook = runGuard()

    hook({}, { name: 'Login' })

    expect(openFeedbackDialog).not.toHaveBeenCalled()
  })

  it('does not open dialog when milestone already triggered', async () => {
    setUsageHours(1)
    const store = setupStore()
    store.triggerMilestone('1h')

    const hook = runGuard()

    hook({}, { name: 'TicketDetailView' })

    await nextTick()

    expect(openFeedbackDialog).not.toHaveBeenCalled()
  })

  it('does not open dialog when no milestone reached', async () => {
    setUsageHours(0)
    setupStore()

    const hook = runGuard()

    hook({}, { name: 'TicketDetailView' })

    await nextTick()

    expect(openFeedbackDialog).not.toHaveBeenCalled()
  })
})
