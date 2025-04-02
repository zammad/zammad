// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'

const waitForConfirmationMock = vi.fn().mockImplementation(() => true)

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: waitForConfirmationMock,
  }),
}))

describe('useNewBetaUi', () => {
  describe('betaUiSwitchEnabled', () => {
    it('returns false when config.ui_desktop_beta_switch is false', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: false })

      const { betaUiSwitchEnabled } = useNewBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns false when user does not have permission', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        lastname: 'Doe',
        firstname: 'John',
      })

      mockPermissions([])

      const { betaUiSwitchEnabled } = useNewBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns false when dismissValue is true', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        lastname: 'Doe',
        firstname: 'John',
      })

      mockPermissions(['user_preferences.beta_ui_switch'])

      localStorage.setItem('beta-ui-switch-dismiss', 'true')

      const { betaUiSwitchEnabled } = useNewBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(false)
    })

    it('returns true when all conditions are met', () => {
      mockApplicationConfig({ ui_desktop_beta_switch: true })

      mockUserCurrent({
        lastname: 'Doe',
        firstname: 'John',
      })

      mockPermissions(['user_preferences.beta_ui_switch'])

      localStorage.setItem('beta-ui-switch-dismiss', 'false')

      const { betaUiSwitchEnabled } = useNewBetaUi()

      expect(betaUiSwitchEnabled.value).toBe(true)
    })
  })

  describe('toggleBetaUiSwitch', () => {
    vi.mock('#shared/utils/pwa.ts')

    beforeEach(() => {
      Object.defineProperty(window, 'location', {
        value: {
          ...window.location,
          pathname: '/desktop',
          href: '/desktop',
        },
      })
    })

    it('sets switchValue to undefined', () => {
      const { switchValue, toggleBetaUiSwitch } = useNewBetaUi()

      expect(switchValue.value).not.toBe(undefined)

      toggleBetaUiSwitch()

      expect(switchValue.value).toBe(undefined)
    })

    it('redirects to root URL', () => {
      const { toggleBetaUiSwitch } = useNewBetaUi()

      expect(window.location.href).toBe('/desktop')

      toggleBetaUiSwitch()

      expect(window.location.href).toBe('/')
    })
  })

  describe('dismissBetaUiSwitch', () => {
    it('shows confirmation dialog', () => {
      const { dismissBetaUiSwitch } = useNewBetaUi()

      dismissBetaUiSwitch()

      expect(waitForConfirmationMock).toHaveBeenCalled()
    })

    it('sets dismissValue to true', () => {
      localStorage.setItem('beta-ui-switch-dismiss', 'false')

      const { dismissValue, dismissBetaUiSwitch } = useNewBetaUi()

      expect(dismissValue.value).toBe(false)

      dismissBetaUiSwitch()

      expect(dismissValue.value).toBe(true)
    })
  })

  describe('toggleDismissBetaUiSwitch', () => {
    it('toggles dismissValue', () => {
      localStorage.setItem('beta-ui-switch-dismiss', 'false')

      const { dismissValue, toggleDismissBetaUiSwitch } = useNewBetaUi()

      expect(dismissValue.value).toBe(false)

      toggleDismissBetaUiSwitch()

      expect(dismissValue.value).toBe(true)

      toggleDismissBetaUiSwitch()

      expect(dismissValue.value).toBe(false)
    })
  })
})
