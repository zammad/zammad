// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'
import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

const waitForConfirmationMock = vi.fn().mockImplementation(() => true)

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: waitForConfirmationMock,
  }),
}))

vi.mock(
  '#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts',
  async (originalModule) => {
    const module =
      await originalModule<typeof import('#desktop/components/CommonDialog/useDialog.ts')>()

    return {
      ...module,
      useFeedbackDialog: () => ({
        openFeedbackDialog: ({ callback }: { callback: () => void }) => {
          callback()
        },
      }),
    }
  },
)

describe('useNewBetaUi', () => {
  beforeEach(() => setActivePinia(createPinia()))
  afterAll(() => vi.clearAllMocks())

  describe('betaUiSwitchEnabled', () => {
    it('returns false when config.ui_desktop_beta_switch is false', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: false })

      const { betaUiSwitchEnabled } = useBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns false when user does not have permission', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        hasBetaUiSwitchAvailable: false,
      })

      const { betaUiSwitchEnabled } = useBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns false when dismissValue is true', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        hasBetaUiSwitchAvailable: true,
      })

      localStorage.setItem('beta-ui-switch-dismiss', 'true')

      const { betaUiSwitchEnabled } = useBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns true when all conditions are met', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        hasBetaUiSwitchAvailable: true,
      })

      localStorage.setItem('beta-ui-switch-dismiss', 'false')

      const { betaUiSwitchEnabled } = useBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(true)
    })
  })

  describe('toggleBetaUiSwitch', () => {
    beforeEach(() => {
      setActivePinia(createPinia())

      vi.doMock('#shared/utils/pwa.ts')
      Object.defineProperty(window, 'location', {
        value: {
          ...window.location,
          pathname: '/desktop',
          href: '/desktop',
        },
      })
    })

    it('sets switchValue and hasFeedbackConsent to null', () => {
      const { hasFeedbackConsent, switchValue, toggleBetaUiSwitch } = useBetaUi()

      expect(switchValue.value).not.toBe(null)
      expect(hasFeedbackConsent.value).not.toBe(null)

      toggleBetaUiSwitch()

      expect(switchValue.value).toBe(null)
      expect(hasFeedbackConsent.value).toBe(null)
    })

    it('supports skipping setting hasFeedbackConsent to null', () => {
      const { hasFeedbackConsent, switchValue, toggleBetaUiSwitch } = useBetaUi()

      expect(switchValue.value).not.toBe(null)
      expect(hasFeedbackConsent.value).not.toBe(null)

      toggleBetaUiSwitch('/', true)

      expect(switchValue.value).toBe(null)
      expect(hasFeedbackConsent.value).not.toBe(null)
    })

    it('redirects to root URL', () => {
      const { toggleBetaUiSwitch } = useBetaUi()

      expect(window.location.href).toBe('/desktop')

      toggleBetaUiSwitch()

      expect(window.location.href).toBe('/')
    })

    it('does not re-trigger milestone dialog after switching back to old UI', async () => {
      // Regression test: previously, resetMilestoneHistory() in clearSwitchAndRedirect
      // used a separate useLocalStorage instance. VueUse synced instances via StorageEvent,
      // which caused the store's milestoneHistory ref to reset to {all: false} while
      // totalAppUsageTime remained above the milestone threshold - flipping
      // shouldTriggerMilestoneDialog back to true immediately after the switch.
      localStorage.setItem('app-usage-total-time', `${5 * 60 * 60 * 1000}`)
      localStorage.setItem(
        'app-usage-milestones-trigger-history',
        JSON.stringify({ '1h': true, '5h': true, '20h': false }),
      )

      const appUsage = useAppUsageStore()

      // Sanity: 5h usage, milestone already seen - dialog must not show.
      expect(appUsage.currentMilestoneKey).toBe('5h')
      expect(appUsage.shouldTriggerMilestoneDialog).toBe(false)

      const { toggleBetaUiSwitch } = useBetaUi()
      toggleBetaUiSwitch('/', true)

      await flushPromises()

      // Both counters must be reset and the dialog must not re-trigger.
      expect(appUsage.totalAppUsageTime).toBe(0)
      expect(appUsage.shouldTriggerMilestoneDialog).toBe(false)
    })

    it('clears usage states', async () => {
      localStorage.setItem('app-usage-total-time', `${1 * 60 * 60 * 1000}`) // 1 hour
      localStorage.setItem(
        'app-usage-milestones-trigger-history',
        JSON.stringify({
          '1h': true,
          '5h': false,
          '20h': false,
        }),
      )
      const { toggleBetaUiSwitch } = useBetaUi()

      toggleBetaUiSwitch('/', true)

      await waitFor(() => expect(localStorage.getItem('app-usage-total-time')).toBe('0'))

      expect(localStorage.getItem('app-usage-milestones-trigger-history')).toBe(
        JSON.stringify({
          '1h': false,
          '5h': false,
          '20h': false,
        }),
      )
    })
  })

  describe('dismissBetaUiSwitch', () => {
    it('shows confirmation dialog', () => {
      const { dismissBetaUiSwitch } = useBetaUi()

      dismissBetaUiSwitch()

      expect(waitForConfirmationMock).toHaveBeenCalled()
    })

    it('sets dismissValue to true', () => {
      localStorage.setItem('beta-ui-switch-dismiss', 'false')

      const { dismissValue, dismissBetaUiSwitch } = useBetaUi()

      expect(dismissValue.value).toBe(false)

      dismissBetaUiSwitch()

      expect(dismissValue.value).toBe(true)
    })
  })
})

describe('toggleDismissBetaUiSwitch', () => {
  beforeEach(() => setActivePinia(createPinia()))

  it('toggles dismissValue', () => {
    localStorage.setItem('beta-ui-switch-dismiss', 'false')

    const { dismissValue, toggleDismissBetaUiSwitch } = useBetaUi()

    expect(dismissValue.value).toBe(false)

    toggleDismissBetaUiSwitch()

    expect(dismissValue.value).toBe(true)

    toggleDismissBetaUiSwitch()

    expect(dismissValue.value).toBe(false)
  })
})
