// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockPublicLinksQuery } from '#shared/entities/public-links/graphql/queries/links.mocks.ts'

describe('testing signup a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
    })
  })

  it('has no accessibility violations', async () => {
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
