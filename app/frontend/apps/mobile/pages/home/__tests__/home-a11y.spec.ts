// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('testing home a11y', () => {
  beforeEach(() => {
    mockUserCurrent({ id: '666' })
    mockTicketOverviews()
  })

  it.skip('home screen has no accessibility violations', async () => {
    const view = await visitView('/')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it.skip('favorite ticket overviews screen has no accessibility violations', async () => {
    const view = await visitView('/favorite/ticket-overviews/edit')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
