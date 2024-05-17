// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

describe('testing locale a11y view', async () => {
  beforeEach(() => {
    mockApplicationConfig({
      two_factor_authentication_method_security_keys: true,
      two_factor_authentication_method_authenticator_app: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/linked-accounts')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
