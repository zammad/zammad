// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'

describe('testing error a11y', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/error')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
