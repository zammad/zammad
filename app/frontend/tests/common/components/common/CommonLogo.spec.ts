// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLogo from '@common/components/common/CommonLogo.vue'
import useApplicationConfigStore from '@common/stores/application/config'
import { getWrapper } from '@tests/support/components'
import { nextTick } from 'vue'

const wrapper = getWrapper(CommonLogo, { store: true })

describe('CommonLogo.vue', () => {
  const configStore = useApplicationConfigStore()

  it('renders custom logo', async () => {
    expect.assertions(2)

    configStore.value.product_name = 'Zammad Custom Logo'

    await nextTick()

    expect(wrapper.attributes().alt).toBe('Zammad Custom Logo')
    expect(wrapper.attributes().src).toBe('/assets/images/logo.svg')
  })

  it('renders default zammad logo', async () => {
    expect.assertions(2)

    configStore.value.product_logo = 'icons/logotype.svg'
    configStore.value.product_name = undefined

    await nextTick()

    expect(wrapper.attributes().alt).toBe(undefined)
    expect(wrapper.attributes().src).toBe('/assets/images/icons/logotype.svg')
  })
})
