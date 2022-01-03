// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLogo from '@common/components/common/CommonLogo.vue'
import useApplicationConfigStore from '@common/stores/application/config'
import { createTestingPinia } from '@pinia/testing'
import { shallowMount } from '@vue/test-utils'

describe('CommonLogo.vue', () => {
  createTestingPinia()
  const configStore = useApplicationConfigStore()

  it('renders custom logo', () => {
    configStore.value.product_name = 'Zammad Custom Logo'

    const wrapper = shallowMount(CommonLogo)

    expect(wrapper.attributes().alt).toBe('Zammad Custom Logo')
    expect(wrapper.attributes().src).toBe('/assets/images/logo.svg')
  })

  it('renders default zammad logo', () => {
    configStore.value.product_logo = 'icons/logotype.svg'
    configStore.value.product_name = undefined

    const wrapper = shallowMount(CommonLogo)

    expect(wrapper.attributes().alt).toBe(undefined)
    expect(wrapper.attributes().src).toBe('/assets/images/icons/logotype.svg')
  })
})
