// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLink from '@common/components/common/CommonLink.vue'
import { nextTick } from 'vue'
import { getVMFromWrapper, getWrapper } from '@tests/support/components'

const wrapperParameters = {
  router: true,
  slots: {
    default: 'A test link',
  },
}

describe('CommonLink.vue', () => {
  let wrapper = getWrapper(CommonLink, {
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
    wrapper = getWrapper(CommonLink, {
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

    wrapper = getWrapper(CommonLink, {
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

    wrapper = getWrapper(CommonLink, {
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
    wrapper = getWrapper(CommonLink, {
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
