// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLogo from '@common/components/common/CommonLogo.vue'
import useApplicationStore from '@common/stores/application'
import { renderComponent } from '@tests/support/components'
import { nextTick } from 'vue'

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
    application.config.product_name = undefined

    await nextTick()

    const img = wrapper.container.querySelector('img')

    expect(img).not.toHaveAttribute('alt')
    expect(img).toHaveAttribute('src', '/assets/images/icons/logotype.svg')
  })
})
