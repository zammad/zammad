// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { visitViewAndMockPasswordConfirmation } from '#desktop/pages/personal-setting/__tests__/support/personal-setting-two-factor-auth.ts'

describe('testing locale a11y view', () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
      two_factor_authentication_method_authenticator_app: true,
    })
  })

  afterEach(() => {
    // Sometimes body is not getting cleared after each test
    document.body.innerHTML = ''
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/two-factor-auth')

    await expect(view.container).toBeAccessible()
  })

  it('has no accessibility violations for authenticator app flyout', async () => {
    const { view } = await visitViewAndMockPasswordConfirmation(false, {
      type: 'authenticatorApp',
      configured: false,
      action: 'setup',
    })

    await expect(view.container).toBeAccessible()
  })

  it('has no accessibility violations for security keys flyout', async () => {
    const { view } = await visitViewAndMockPasswordConfirmation(false, {
      type: 'securityKeys',
      configured: false,
      action: 'setup',
    })

    await expect(view.container).toBeAccessible()
  })
})
