// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonLogo from '../CommonLogo.vue'

describe('CommonLogo.vue', () => {
  it('renders custom logo', async () => {
    const wrapper = renderComponent(CommonLogo, { store: true })
    const application = useApplicationStore()

    application.config.product_logo = '1234'
    application.config.product_name = 'Zammad Custom Logo'

    await nextTick()

    const img = wrapper.container.querySelector('img')

    expect(img).toHaveAttribute('alt', 'Zammad Custom Logo')
    expect(img).toHaveAttribute(
      'src',
      '/api/v1/system_assets/product_logo/1234',
    )
  })

  it('renders default zammad logo', async () => {
    const wrapper = renderComponent(CommonLogo, { store: true })
    const application = useApplicationStore()

    application.config.product_logo = 'logo.svg'
    application.config.product_name = ''

    await nextTick()

    const img = wrapper.container.querySelector('img')

    expect(img).toHaveAttribute('alt', '')
    expect(img).toHaveAttribute(
      'src',
      '/api/v1/system_assets/product_logo/logo.svg',
    )
  })
})
