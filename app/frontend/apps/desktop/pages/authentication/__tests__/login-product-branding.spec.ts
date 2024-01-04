// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import '#tests/graphql/builders/mocks.ts'

const applicationConfig = {
  product_name: 'Zammad Example App',
  product_logo: 'example-logo.svg',
}

describe('testing login product branding', () => {
  beforeEach(() => {
    mockApplicationConfig(applicationConfig)
  })

  it('check that expected product name is present', async () => {
    const view = await visitView('/login')

    expect(view.getByText(applicationConfig.product_name)).toBeInTheDocument()
  })

  it('check that expected product logo is present', async () => {
    const view = await visitView('/login')

    const logo = view.getByIconName('logo-flat')

    expect(logo).toBeInTheDocument()
  })

  it('check that expected footer logo is present', async () => {
    const view = await visitView('/login')

    const logo = view.getByIconName('logo-flat')

    expect(logo).toBeInTheDocument()

    const link = logo.parentElement?.parentElement

    expect(link).toHaveAttribute('href', 'https://zammad.org')
    expect(link).toHaveAttribute('target', '_blank')
  })
})
