// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'

describe('testing error a11y', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/error')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})

describe('testing error tag a11y', () => {
  it('has no accessibility violations', async () => {
    mockAuthentication(true)

    const view = await visitView('/error-tab')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
