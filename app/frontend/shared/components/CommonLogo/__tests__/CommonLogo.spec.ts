// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'
import { renderComponent } from '@tests/support/components'
import { useApplicationStore } from '@shared/stores/application'
import CommonLogo from '../CommonLogo.vue'

describe('CommonLogo.vue', () => {
  it('renders custom logo', async () => {
    const wrapper = renderComponent(CommonLogo, { store: true })
    const application = useApplicationStore()

    application.config.product_name = 'Zammad Custom Logo'

    await nextTick()

    const img = wrapper.container.querySelector('img')

    expect(img).toHaveAttribute('alt', 'Zammad Custom Logo')
    expect(img).toHaveAttribute('src', '/assets/images/logo.svg')
  })

  it('renders default zammad logo', async () => {
    const wrapper = renderComponent(CommonLogo, { store: true })
    const application = useApplicationStore()

    application.config.product_logo = 'icons/logotype.svg'
    delete application.config.product_name

    await nextTick()

    const img = wrapper.container.querySelector('img')

    expect(img).not.toHaveAttribute('alt')
    expect(img).toHaveAttribute('src', '/assets/images/icons/logotype.svg')
  })
})
