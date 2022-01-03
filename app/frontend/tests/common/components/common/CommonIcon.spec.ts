// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { shallowMount } from '@vue/test-utils'
import CommonIcon from '@common/components/common/CommonIcon.vue'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = shallowMount(CommonIcon, {
      props: { name: 'arrow-left' },
    })
    expect(wrapper.classes()).toContain('icon')
  })
  it('renders icon with animation', () => {
    const wrapper = shallowMount(CommonIcon, {
      props: { name: 'cog', animation: 'spin' },
    })
    expect(wrapper.classes()).toContain('animate-spin')
  })
  it('renders icon with small size', () => {
    const wrapper = shallowMount(CommonIcon, {
      props: { name: 'cog', size: 'small' },
    })

    expect(wrapper.attributes().width).toEqual('20')
    expect(wrapper.attributes().height).toEqual('20')
  })
  it('renders a decorative icon', () => {
    const wrapper = shallowMount(CommonIcon, {
      props: { name: 'cog', decorative: true },
    })

    expect(wrapper.attributes()['aria-hidden']).toEqual('true')
  })
  it('triggers click handler of icon', () => {
    const wrapper = shallowMount(CommonIcon, {
      props: { name: 'dashboard' },
    })

    wrapper.trigger('click')
    expect(wrapper.emitted('click')).toHaveLength(1)
  })
})
