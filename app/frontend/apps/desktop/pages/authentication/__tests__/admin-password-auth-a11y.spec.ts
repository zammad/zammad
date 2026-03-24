// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import '#tests/graphql/builders/mocks.ts'

describe('testing admin password request a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_show_password_login: false,
      auth_github: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/admin-password-auth')
    await expect(view.container).toBeAccessible()
  })
})
