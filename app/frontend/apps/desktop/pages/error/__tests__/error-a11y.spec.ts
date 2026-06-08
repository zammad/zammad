// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'

describe('testing error a11y', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/error')
    await expect(view.container).toBeAccessible()
  })
})

describe('testing error tag a11y', () => {
  it('has no accessibility violations', async () => {
    mockAuthentication(true)

    const view = await visitView('/error-tab')
    await expect(view.container).toBeAccessible()
  })
})
