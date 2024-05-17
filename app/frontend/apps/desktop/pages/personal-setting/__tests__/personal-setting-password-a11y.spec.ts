// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

describe('testing password a11y view', async () => {
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

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/password')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
