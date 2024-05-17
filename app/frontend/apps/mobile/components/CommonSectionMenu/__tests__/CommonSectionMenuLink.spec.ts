// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonSectionMenuLink from '../CommonSectionMenuLink.vue'

const renderMenuItem = (props: any = {}, slots: any = {}) => {
  return renderComponent(CommonSectionMenuLink, {
    props,
    slots,
    shallow: false,
    router: true,
    store: true,
  })
}

describe('rendering item for section', () => {
  it('renders a link, if link is provided', () => {
    const view = renderMenuItem({
      link: '/',
      label: 'Test Title',
    })

    expect(view.getByTestId('section-menu-link').tagName).toBe('A')
    expect(view.getByText('Test Title')).toBeInTheDocument()
    expect(view.getByIconName('chevron-right')).toBeInTheDocument()
  })

  it('has an icon, if provided', () => {
    const view = renderMenuItem({
      link: '/',
      icon: 'home',
    })

    expect(view.getByIconName('home')).toBeInTheDocument()
  })

  it('has an icon with a background', () => {
    const view = renderMenuItem({
      link: '/',
      iconBg: 'bg-red',
      icon: 'home',
    })

    const icon = view.getByTestId('wrapper-icon')

    expect(icon).toHaveClass('bg-red')
    expect(icon).toHaveClass('rounded-lg')
  })

  it('accepts icon as object', () => {
    const view = renderMenuItem({
      link: '/',
      icon: { name: 'home', fixedSize: { width: 40, height: 40 } },
    })

    const icon = view.getByIconName('home')

    expect(icon).toBeInTheDocument()

    expect(icon).toHaveAttribute('width', '40')
    expect(icon).toHaveAttribute('height', '40')
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
      { label: 'Some Title', link: '/' },
      {
        default: 'Slot Title',
      },
    )

    // slor overrides prop
    expect(view.queryByText('Some Title')).not.toBeInTheDocument()
    expect(view.getByText('Slot Title')).toBeInTheDocument()
  })
})
