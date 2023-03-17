// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '@shared/stores/application'
import { renderComponent } from '@tests/support/components'
import type { MountingOptions } from '@vue/test-utils'
import CommonLink, { type Props } from '../CommonLink.vue'

const wrapperParameters = {
  router: true,
  slots: {
    default: 'A test link',
  },
}

const renderCommonLink = (options: MountingOptions<Props> = {}) => {
  const view = renderComponent(CommonLink, {
    ...wrapperParameters,
    props: {
      link: 'https://www.zammad.org',
    },
    ...options,
  })

  return {
    ...view,
    getLink: () => view.getByTestId('common-link'),
  }
}

describe('CommonLink.vue', () => {
  it('renders external link element with attributes', () => {
    const { getLink } = renderCommonLink()
    const link = getLink()
    expect(link).toHaveTextContent('A test link')
    expect(link).toHaveAttribute('href', 'https://www.zammad.org')
    expect(link).not.toHaveAttribute('target')
  })

  it('supports click event', async (context) => {
    context.skipConsole = true

    const { getLink, ...wrapper } = renderCommonLink()

    const link = getLink()

    await wrapper.events.click(link)

    expect(wrapper.emitted().click).toBeTruthy()

    const emittedClick = wrapper.emitted().click as Array<Array<MouseEvent>>

    expect(emittedClick[0][0].isTrusted).toEqual(false)
  })

  it('supports disabled prop', async () => {
    const { getLink, ...wrapper } = renderCommonLink({
      props: {
        link: 'https://www.zammad.org',
        disabled: true,
      },
    })

    const link = getLink()

    expect(link).toHaveClass('pointer-events-none')

    await wrapper.events.click(link)

    expect(wrapper.emitted().click).toBeFalsy()
  })

  it('title attribute can be used without a real prop', async () => {
    const title = 'a link title'

    const { getLink, ...wrapper } = renderCommonLink({
      props: {
        link: 'https://www.zammad.org',
      },
      attrs: {
        title,
      },
    })
    expect(getLink()).toHaveAttribute('title', title)

    await wrapper.rerender({
      openInNewTab: true,
    })

    expect(getLink()).toHaveAttribute('target', '_blank')

    await wrapper.rerender({
      target: '_self',
    })

    expect(getLink()).toHaveAttribute('target', '_self')
  })

  it('link route detection', async () => {
    const { getLink, ...wrapper } = renderCommonLink({
      props: {
        link: '/example',
      },
    })

    expect(getLink()).toHaveAttribute('href', '/example')

    await wrapper.rerender({
      link: 'https://www.zammad.org',
    })

    expect(getLink()).toHaveAttribute('href', 'https://www.zammad.org')

    await wrapper.rerender({
      link: '/#hello-world',
    })

    expect(getLink()).toHaveAttribute('href', '/#hello-world')
  })

  it('supports link prop with route object', () => {
    const { getLink } = renderCommonLink({
      props: {
        link: {
          name: 'Example',
        },
      },
    })

    const link = getLink()

    expect(link).toHaveTextContent('A test link')
    expect(link).toHaveAttribute('href', '/example')
  })

  it('supports api urls', () => {
    const app = useApplicationStore()
    app.config.api_path = '/api'
    const { getLink } = renderCommonLink({
      props: {
        link: '/example',
        restApi: true,
      },
    })
    expect(getLink()).toHaveAttribute('href', '/api/example')
  })
})
