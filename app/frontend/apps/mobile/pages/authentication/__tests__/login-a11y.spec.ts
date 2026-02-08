// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('testing login a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      product_name: 'Zammad Test System',
    })
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it.skip('has no accessibility violations', async () => {
    const view = await visitView('/login')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
