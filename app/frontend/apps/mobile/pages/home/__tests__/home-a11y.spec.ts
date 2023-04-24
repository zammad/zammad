// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockAccount } from '#tests/support/mock-account.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

describe('testing home a11y', () => {
  beforeEach(() => {
    mockAccount({ id: '666' })
    mockTicketOverviews()
  })

  it('home screen has no accessibility violations', async () => {
    const view = await visitView('/')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('favorite ticket overviews screen has no accessibility violations', async () => {
    const view = await visitView('/favorite/ticker-overviews/edit')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
