// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'

describe('personal new beta ui settings', async () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.beta_ui_switch'])

    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })

    Object.defineProperty(window, 'location', {
      value: {
        ...window.location,
        pathname: '/desktop',
        href: '/desktop',
      },
    })
  })

  it('renders view correctly', async () => {
    const view = await visitView('/personal-setting/new-beta-ui')

    const switchToggleField = await view.findByLabelText(
      'Display Zammad with the New BETA User Interface',
    )
    expect(switchToggleField).toBeInTheDocument()

    const dismissCheckbox = await view.findByLabelText(
      'Have the BETA switch between the old and the new UI always available in the Primary Navigation',
    )
    expect(dismissCheckbox).toBeInTheDocument()

    const { switchValue, dismissValue } = useNewBetaUi()

    expect(switchValue.value).toBe(false)
    expect(dismissValue.value).toBe(false)

    await dismissCheckbox.click()
    expect(dismissValue.value).toBe(true)

    await dismissCheckbox.click()
    expect(dismissValue.value).toBe(false)
  })
})
