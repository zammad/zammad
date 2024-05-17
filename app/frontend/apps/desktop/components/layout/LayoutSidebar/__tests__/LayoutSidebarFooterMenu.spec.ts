// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import LayoutSidebarFooterMenu from '../LayoutSidebarFooterMenu.vue'

describe('layout sidebar footer menu', () => {
  beforeEach(() => {
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
    })
  })

  it('renders user avatar', async () => {
    const view = renderComponent(LayoutSidebarFooterMenu)

    expect(view.getByText('JD')).toBeInTheDocument()

    const avatar = view.getByTestId('common-avatar')
    expect(avatar).toHaveClass('size-normal')
  })

  it('renders small user avatar in collapsed mode', async () => {
    const view = renderComponent(LayoutSidebarFooterMenu, {
      props: { collapsed: true },
    })

    expect(view.getByText('JD')).toBeInTheDocument()

    const avatar = view.getByTestId('common-avatar')
    expect(avatar).toHaveClass('size-small')
  })
})
