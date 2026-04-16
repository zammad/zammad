// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'

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
      vi.doMock('#shared/utils/pwa.ts')
      Object.defineProperty(window, 'location', {
        value: {
          ...window.location,
          pathname: '/desktop',
          href: '/desktop',
        },
      })
    })

    it('sets switchValue and hasFeedbackConsent to undefined', () => {
      const { hasFeedbackConsent, switchValue, toggleBetaUiSwitch } = useBetaUi()

      expect(switchValue.value).not.toBe(undefined)
      expect(hasFeedbackConsent.value).not.toBe(undefined)

      toggleBetaUiSwitch()

      expect(switchValue.value).toBe(undefined)
      expect(hasFeedbackConsent.value).toBe(undefined)
    })

    it('supports skipping setting hasFeedbackConsent to undefined', () => {
      const { hasFeedbackConsent, switchValue, toggleBetaUiSwitch } = useBetaUi()

      expect(switchValue.value).not.toBe(undefined)
      expect(hasFeedbackConsent.value).not.toBe(undefined)

      toggleBetaUiSwitch('/', true)

      expect(switchValue.value).toBe(undefined)
      expect(hasFeedbackConsent.value).not.toBe(undefined)
    })

    it('redirects to root URL', () => {
      const { toggleBetaUiSwitch } = useBetaUi()

      expect(window.location.href).toBe('/desktop')

      toggleBetaUiSwitch()

      expect(window.location.href).toBe('/')
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

      await waitFor(() =>
        expect(localStorage.getItem('app-usage-total-time')).toBe(`${1 * 60 * 60 * 1000}`),
      )

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
