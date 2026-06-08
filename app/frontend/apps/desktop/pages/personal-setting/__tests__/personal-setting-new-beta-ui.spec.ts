// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

const openFeedbackDialogMock = vi.fn()

vi.mock(
  '#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts',
  async (originalModule) => {
    const module =
      await originalModule<typeof import('#desktop/components/CommonDialog/useDialog.ts')>()

    return {
      ...module,
      useFeedbackDialog: () => ({
        openFeedbackDialog: openFeedbackDialogMock,
      }),
    }
  },
)

describe('personal BETA UI settings', () => {
  beforeEach(() => {
    localStorage.clear()

    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.beta_ui_switch'])

    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
  })

  it('renders view correctly', async () => {
    localStorage.setItem('beta-ui-switch', 'true')

    const view = await visitView('/personal-setting/new-beta-ui')

    const switchToggleField = await view.findByLabelText(
      'Display Zammad with the new BETA user interface',
    )
    expect(switchToggleField).toBeInTheDocument()

    const dismissCheckbox = await view.findByLabelText(
      'Show the BETA switch between the old and the new UI in the primary navigation',
    )
    expect(dismissCheckbox).toBeInTheDocument()

    expect(localStorage.getItem('beta-ui-switch-dismiss')).toBe('false')

    await dismissCheckbox.click()
    expect(localStorage.getItem('beta-ui-switch-dismiss')).toBe('true')

    await dismissCheckbox.click()
    expect(localStorage.getItem('beta-ui-switch-dismiss')).toBe('false')
  })

  it('opens manual feedback dialog', async () => {
    localStorage.setItem('beta-ui-feedback-consent', 'true')
    localStorage.setItem('beta-ui-switch', 'true')

    const view = await visitView('/personal-setting/new-beta-ui')

    const feedbackLink = view.getByText('Give feedback')

    await view.events.click(feedbackLink)

    expect(openFeedbackDialogMock).toHaveBeenCalled()
  })
})
