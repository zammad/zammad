// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'

describe('testing appearance a11y view', async () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/appearance')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
