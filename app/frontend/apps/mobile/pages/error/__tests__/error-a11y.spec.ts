// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'

describe('testing error a11y', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/error')
    await expect(view.container).toBeAccessible()
  })
})
