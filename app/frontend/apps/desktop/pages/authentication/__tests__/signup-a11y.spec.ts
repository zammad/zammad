// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockPublicLinksQuery } from '#shared/entities/public-links/graphql/queries/links.mocks.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('testing signup a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
    })
  })

  it.skip('has no accessibility violations', async () => {
    const publicLinks = [
      {
        title: 'Imprint',
        link: 'https://example.com/imprint',
        description: 'A test description',
      },
      {
        title: 'Privacy policy',
        link: 'https://example.com/privacy',
        description: null,
      },
    ]

    mockPublicLinksQuery({
      publicLinks,
    })

    const view = await visitView('/signup')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
