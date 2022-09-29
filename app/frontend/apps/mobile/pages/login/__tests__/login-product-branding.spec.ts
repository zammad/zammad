// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'

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

    const logo = view.getByAltText(applicationConfig.product_name)

    expect(logo).toBeInTheDocument()
    expect(logo).toHaveAttribute(
      'src',
      `/assets/images/${applicationConfig.product_logo}`,
    )
  })
})
