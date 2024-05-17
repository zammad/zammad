// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import LayoutPublicPage from '../LayoutPublicPage/LayoutPublicPage.vue'

const applicationConfig = {
  product_name: 'Zammad Example App',
  product_logo: 'example-logo.svg',
}

describe('public page layout', () => {
  beforeEach(() => {
    mockApplicationConfig(applicationConfig)
  })

  it('renders title and logo', async () => {
    const view = renderComponent(LayoutPublicPage, {
      props: {
        title: 'Example Title',
        showLogo: true,
      },
      router: true,
    })

    expect(view.getByText('Example Title')).toBeInTheDocument()

    const logo = view.getByAltText(applicationConfig.product_name)
    expect(logo).toBeInTheDocument()
  })
})
