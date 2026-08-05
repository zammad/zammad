// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import FormFieldLink from '#shared/components/Form/FormFieldLink.vue'

const renderFormFieldLink = (props: Record<string, unknown> = {}) =>
  renderComponent(FormFieldLink, {
    router: true,
    props: {
      id: 'test-link',
      link: 'https://www.zammad.org',
      ...props,
    },
  })

describe('FormFieldLink.vue', () => {
  it('marks the container with the formkit-link class', () => {
    const wrapper = renderFormFieldLink()

    const container = wrapper.container.querySelector('.formkit-link')

    expect(container).toBeInTheDocument()
  })

  it('renders an anchor which opens the link in a new tab', () => {
    const wrapper = renderFormFieldLink()

    const anchor = wrapper.getByTestId('common-link')

    expect(anchor).toHaveAttribute('href', 'https://www.zammad.org')
    expect(anchor).toHaveAttribute('target', '_blank')
  })

  it('renders the link label as visible text if requested', () => {
    const wrapper = renderFormFieldLink({
      linkLabel: 'Open external reference',
      showLinkLabel: true,
    })

    expect(wrapper.getByTestId('common-link')).toHaveTextContent('Open external reference')
  })
})
