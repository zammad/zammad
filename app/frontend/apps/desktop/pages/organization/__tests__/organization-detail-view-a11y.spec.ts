// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('Organization Detail View', () => {
  it.skip('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    const view = await visitView('/organizations/1')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
