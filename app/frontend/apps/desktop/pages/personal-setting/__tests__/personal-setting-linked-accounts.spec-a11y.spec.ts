// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

describe('testing locale a11y view', () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
      two_factor_authentication_method_authenticator_app: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/linked-accounts')

    await expect(view.container).toBeAccessible()
  })
})
