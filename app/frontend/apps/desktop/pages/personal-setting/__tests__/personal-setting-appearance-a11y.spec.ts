// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'

describe('testing appearance a11y view', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/appearance')
    await expect(view.container).toBeAccessible()
  })
})
