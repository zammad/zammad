// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { visitView } from '@tests/support/components/visitView'
import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '@shared/entities/public-links/__tests__/mocks/mockPublicLinks'

describe('testing login a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      product_name: 'Zammad Test System',
    })
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/login')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
