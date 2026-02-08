// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('testing locale a11y view', () => {
  it.skip('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/locale')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
