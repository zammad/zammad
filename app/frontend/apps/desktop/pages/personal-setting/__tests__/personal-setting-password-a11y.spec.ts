// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('testing password a11y view', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    mockPermissions(['user_preferences.password'])

    mockApplicationConfig({
      user_show_password_login: true,
    })
  })

  it.skip('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/password')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
