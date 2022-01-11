// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { shallowMount, type VueWrapper } from '@vue/test-utils'
import CommonLink from '@common/components/common/CommonLink.vue'
import { createRouter, createWebHistory } from 'vue-router'
import { ComponentPublicInstance, nextTick } from 'vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      name: 'Home',
      path: '/',
      component: {
        template: 'Welcome to the zammad app',
      },
    },
    {
      name: 'Example',
      path: '/example',
      component: {
        template: 'This is a example page',
      },
    },
  ],
})

// Workaround to get the vm from the wrapper without type complaining.
const getVMFromWrapper = (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  wrapper: VueWrapper<ComponentPublicInstance<any>>,
) => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return wrapper.vm as any
}

const wrapperParameters = {
  global: {
    plugins: [router],
    stubs: {
      RouterLink: false,
    },
  },
  slots: {
    default: 'A test link',
  },
}

describe('CommonLink.vue', () => {
  let wrapper = shallowMount(CommonLink, {
    ...wrapperParameters,
    props: {
      link: 'https://www.zammad.org',
    },
  })

  it('mounted successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('renders external link element with attributes', () => {
    expect(wrapper.find('a').text()).toBe('A test link')
    expect(wrapper.attributes().href).toBe('https://www.zammad.org')
    expect(wrapper.attributes().target).toBeUndefined()
  })

  it('supports click event', () => {
    wrapper.find('a').trigger('click')

    expect(wrapper.emitted('click')).toBeTruthy()

    const emittedClick = wrapper.emitted().click as Array<Array<MouseEvent>>

    expect(emittedClick[0][0].isTrusted).toEqual(false)
  })

  it('supports disabled prop', async () => {
    expect.assertions(2)
    wrapper = shallowMount(CommonLink, {
      ...wrapperParameters,
      props: {
        link: 'https://www.zammad.org',
        disabled: true,
      },
    })
    await nextTick()

    expect(wrapper.attributes().class).toContain('pointer-events-none')

    wrapper.find('a').trigger('click')

    expect(wrapper.emitted('click')).toBeFalsy()
  })

  it('title attribute can be used without a real prop', () => {
    const title = 'a link title'

    wrapper = shallowMount(CommonLink, {
      ...wrapperParameters,
      props: {
        link: 'https://www.zammad.org',
      },
      attrs: {
        title,
      },
    })

    expect(wrapper.attributes().title).toBe(title)
  })

  it('open link in a new tab', async () => {
    expect.assertions(1)

    wrapper.setProps({
      openInNewTab: true,
    })
    await nextTick()

    expect(wrapper.attributes().target).toBe('_blank')
  })

  it('supports isExternal prop', async () => {
    expect.assertions(1)

    wrapper.setProps({
      isExternal: true,
    })
    await nextTick()

    expect(getVMFromWrapper(wrapper).isInternalLink).toBe(false)
  })

  it('supports isRoute prop', async () => {
    expect.assertions(1)

    wrapper.setProps({
      isExternal: false,
      isRoute: true,
    })
    await nextTick()

    expect(getVMFromWrapper(wrapper).isInternalLink).toBe(true)
  })

  it('direct setting of a target', async () => {
    expect.assertions(1)

    wrapper.setProps({
      target: '_self',
    })
    await nextTick()

    expect(wrapper.attributes().target).toBe('_self')
  })

  it('link route detection', async () => {
    expect.assertions(4)

    wrapper = shallowMount(CommonLink, {
      ...wrapperParameters,
      props: {
        link: '/example',
      },
    })

    expect(getVMFromWrapper(wrapper).isInternalLink).toBe(true)
    expect(wrapper.attributes().href).toBe('/example')

    wrapper.setProps({
      link: '/external-path',
    })
    await nextTick()

    expect(getVMFromWrapper(wrapper).isInternalLink).toBe(false)
    expect(wrapper.attributes().href).toBe('/external-path')
  })

  it('supports link prop with route object', () => {
    wrapper = shallowMount(CommonLink, {
      ...wrapperParameters,
      props: {
        link: {
          name: 'Example',
        },
      },
    })

    expect(wrapper.find('a').text()).toBe('A test link')
    expect(wrapper.attributes().href).toBe('/example')
  })
})
