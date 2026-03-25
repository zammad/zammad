// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

describe('testing new-beta-ui a11y view', () => {
  beforeEach(() => {
    mockPermissions(['user_preferences.beta_ui_switch'])

    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/new-beta-ui')
    await expect(view.container).toBeAccessible()
  })
})
