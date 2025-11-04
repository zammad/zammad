// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { findByIconName } from '#tests/support/components/iconQueries.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import UserListPopoverWithTrigger, { type Props } from '../UserListPopoverWithTrigger.vue'

const dummyUsers = [
  {
    id: convertToGraphQLId('User', 2),
    internalId: 2,
    fullname: 'Nicole Braun',
    email: 'nicole.braun@zammad.org',
  },
  {
    id: convertToGraphQLId('User', 3),
    internalId: 3,
    fullname: 'Agent 1 Test',
    email: 'agent1@example.com',
  },
]

const renderUserListPopover = (props?: Partial<Props>) =>
  renderComponent(UserListPopoverWithTrigger, {
    props: {
      ...props,
      users: dummyUsers,
    },
    router: true,
  })

describe('UserListPopoverWithTrigger', () => {
  it('renders user overflow count', () => {
    const wrapper = renderUserListPopover()

    expect(wrapper.getByText('+2')).toBeVisible()
  })

  it('displays the user list popover', async () => {
    const wrapper = renderUserListPopover()

    await wrapper.events.hover(wrapper.getByText('+2'))

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByRole('img', { name: 'Avatar (Nicole Braun)' })).toBeVisible()

    expect(
      await within(popover).findByRole('link', { name: dummyUsers[0].fullname }),
    ).toHaveAttribute('href', `/user/profile/${dummyUsers[0].internalId}`)

    expect(await within(popover).findByRole('img', { name: 'Avatar (Agent 1 Test)' })).toBeVisible()

    expect(
      await within(popover).findByRole('link', { name: dummyUsers[1].fullname }),
    ).toHaveAttribute('href', `/user/profile/${dummyUsers[1].internalId}`)
  })

  it('supports optional live user information', async () => {
    const wrapper = renderUserListPopover({
      liveUsers: [
        {
          editing: true,
          app: EnumTaskbarApp.Mobile,
          isIdle: false,
        },
        {
          editing: false,
          app: EnumTaskbarApp.Desktop,
          isIdle: true,
        },
      ],
    })

    await wrapper.events.hover(wrapper.getByText('+2'))

    const popover = await wrapper.findByRole('region')

    expect(await findByIconName(popover, 'phone-pencil')).toHaveAccessibleName(
      'User is editing on mobile',
    )

    expect(await findByIconName(popover, 'user-idle-2')).toHaveAccessibleName('User is idle')
  })
})
