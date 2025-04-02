// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

describe('testing new-beta-ui a11y view', async () => {
  beforeEach(() => {
    mockPermissions(['user_preferences.beta_ui_switch'])

    mockApplicationConfig({
      ui_desktop_beta_switch: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/new-beta-ui')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
