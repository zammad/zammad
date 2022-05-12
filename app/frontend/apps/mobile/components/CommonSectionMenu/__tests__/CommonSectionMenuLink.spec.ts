// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonSectionMenuLink from '../CommonSectionMenuLink.vue'

const renderMenuItem = (props: any = {}, slots: any = {}) => {
  return renderComponent(CommonSectionMenuLink, {
    props,
    slots,
    shallow: false,
    router: true,
  })
}

describe('rendering item for section', () => {
  it('renders a link, if link is provided', () => {
    const view = renderMenuItem({
      link: '/',
      title: 'Test Title',
    })

    expect(view.getByTestId('section-menu-link').tagName).toBe('A')
    expect(view.getByText('Test Title')).toBeInTheDocument()
    expect(view.getIconByName('arrow-right')).toBeInTheDocument()
  })

  it('has an icon, if provided', () => {
    const view = renderMenuItem({
      link: '/',
      icon: 'home',
    })

    expect(view.getIconByName('home')).toBeInTheDocument()
  })

  it("draws information, if it's provided", () => {
    const view = renderMenuItem({
      link: '/',
      information: 'Test Information',
    })

    expect(view.getByText('Test Information')).toBeInTheDocument()
  })

  it('draws right slot, if provided', () => {
    const view = renderMenuItem(
      {
        link: '/',
      },
      {
        right: 'Test Information',
      },
    )

    expect(view.getByText('Test Information')).toBeInTheDocument()
  })

  it('draws default slot, if provided', () => {
    const view = renderMenuItem(
      { title: 'Some Title', link: '/' },
      {
        default: 'Slot Title',
      },
    )

    // slor overrides prop
    expect(view.queryByText('Some Title')).not.toBeInTheDocument()
    expect(view.getByText('Slot Title')).toBeInTheDocument()
  })
})
