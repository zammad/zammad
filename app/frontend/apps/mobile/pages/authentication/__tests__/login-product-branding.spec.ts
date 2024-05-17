// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '#shared/entities/public-links/__tests__/mocks/mockPublicLinks.ts'

const applicationConfig = {
  product_name: 'Zammad Example App',
  product_logo: 'example-logo.svg',
}

describe('testing login product branding', () => {
  beforeEach(() => {
    mockApplicationConfig(applicationConfig)
    mockPublicLinks([])
    mockPublicLinksSubscription()
  })

  it('check that expected product name is present', async () => {
    const view = await visitView('/login')

    expect(view.getByText(applicationConfig.product_name)).toBeInTheDocument()
  })

  it('check that expected product logo is present', async () => {
    const view = await visitView('/login')

    const logo = view.getByAltText(applicationConfig.product_name)

    expect(logo).toBeInTheDocument()
    expect(logo).toHaveAttribute(
      'src',
      `/api/v1/system_assets/product_logo/${applicationConfig.product_logo}`,
    )
  })

  it('check that expected footer logo is present', async () => {
    const view = await visitView('/login')

    const logo = view.getByAltText('Logo')

    expect(logo).toBeInTheDocument()
    expect(logo).toHaveAttribute('src', '/assets/images/icons/logo.svg')

    const link = logo.parentElement

    expect(link).toHaveAttribute('href', 'https://zammad.org')
    expect(link).toHaveAttribute('target', '_blank')
  })
})
