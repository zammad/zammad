// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  getByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'

import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'

import TicketLiveUsers, {
  type Props,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketLiveUsers.vue'

import liveUserList from './mocks/live-user-list.json'

const renderTicketLiveUsers = (props?: Partial<Props>) =>
  renderComponent(TicketLiveUsers, {
    props: {
      liveUserList: liveUserList as TicketLiveAppUser[],
      ...props,
    },
  })

vi.hoisted(() => {
  vi.useFakeTimers().setSystemTime(new Date('2024-09-17T11:51:00Z'))
})

describe('TicketLiveUsers', () => {
  it('shows editing/app indicator icons', async () => {
    const wrapper = renderTicketLiveUsers()

    const customerAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(
      queryByIconName(customerAvatar.parentElement!, 'pencil'),
    ).not.toBeInTheDocument()

    expect(
      queryByIconName(customerAvatar.parentElement!, 'phone'),
    ).not.toBeInTheDocument()

    expect(
      queryByIconName(customerAvatar.parentElement!, 'phone-pencil'),
    ).not.toBeInTheDocument()

    const adminAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Test Admin Agent)',
    })

    expect(
      getByIconName(adminAvatar.parentElement!, 'pencil'),
    ).toBeInTheDocument()

    const agent1Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 1 Test)',
    })

    expect(
      getByIconName(agent1Avatar.parentElement!, 'phone'),
    ).toBeInTheDocument()

    const agent2Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 2 Test)',
    })

    expect(
      getByIconName(agent2Avatar.parentElement!, 'phone-pencil'),
    ).toBeInTheDocument()
  })

  it('does not show avatars if there are no live users', async () => {
    const wrapper = renderTicketLiveUsers({
      liveUserList: [],
    })

    expect(wrapper.queryByRole('img')).not.toBeInTheDocument()
  })

  it('renders idle users in an appropriate style', async () => {
    const wrapper = renderTicketLiveUsers()

    const customerAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(customerAvatar).toHaveClass('opacity-60')

    expect(
      getByIconName(customerAvatar.parentElement!, 'user-idle-2'),
    ).toHaveClasses(['fill-stone-200', 'dark:fill-neutral-500'])

    const adminAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Test Admin Agent)',
    })

    expect(adminAvatar).not.toHaveClass('opacity-60')

    expect(getByIconName(adminAvatar.parentElement!, 'pencil')).toHaveClasses([
      'text-black',
      'dark:text-white',
    ])

    const agent1Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 1 Test)',
    })

    expect(agent1Avatar).not.toHaveClass('opacity-60')

    expect(getByIconName(agent1Avatar.parentElement!, 'phone')).toHaveClasses([
      'text-black',
      'dark:text-white',
    ])

    const agent2Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 2 Test)',
    })

    expect(agent2Avatar).toHaveClass('opacity-60')

    expect(
      getByIconName(agent2Avatar.parentElement!, 'phone-pencil'),
    ).toHaveClasses(['fill-stone-200', 'dark:fill-neutral-500'])
  })
})
