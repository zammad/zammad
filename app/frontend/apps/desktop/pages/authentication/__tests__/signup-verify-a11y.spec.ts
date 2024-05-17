// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

describe('testing signup verify a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/signup/verify')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
