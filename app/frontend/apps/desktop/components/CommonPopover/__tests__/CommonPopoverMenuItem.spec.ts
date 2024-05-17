// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPopoverMenuItem from '../CommonPopoverMenuItem.vue'

const renderMenuItem = (props: any = {}, slots: any = {}) => {
  return renderComponent(CommonPopoverMenuItem, {
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

    expect(view.getByTestId('popover-menu-item').tagName).toBe('A')
    expect(view.getByText('Test Title')).toBeInTheDocument()
  })

  it('has an icon, if provided', () => {
    const view = renderMenuItem({
      link: '/',
      icon: 'search',
    })

    expect(view.getByIconName('search')).toBeInTheDocument()
  })
})
