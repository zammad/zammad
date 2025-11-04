// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName, queryByIconName } from '#tests/support/components/iconQueries.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'

import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketLiveUsers, {
  type Props,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketLiveUsers.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import liveUserList from './mocks/live-user-list.json'

const renderTicketLiveUsers = (
  props?: Partial<Props>,
  options?: Parameters<typeof createDummyTicket>[0],
) =>
  renderComponent(TicketLiveUsers, {
    props: {
      liveUserList: liveUserList as TicketLiveAppUser[],
      ...props,
    },
    router: true,
    provide: [[TICKET_KEY, { ticket: createDummyTicket(options) }]],
  })

vi.hoisted(() => {
  vi.useFakeTimers().setSystemTime(new Date('2024-09-17T11:51:00Z'))
})

describe('TicketLiveUsers', () => {
  beforeEach(() => {
    mockUserQuery({
      user: {
        id: convertToGraphQLId('User', 3),
        internalId: 3,
        fullname: 'Agent 2 Test',
        vip: false,
        organization: {
          id: convertToGraphQLId('Organization', 1),
          internalId: 1,
          name: 'Zammad Foundation',
          active: true,
          ticketsCount: {
            open: 5,
            closed: 0,
          },
        },
        secondaryOrganizations: {
          edges: [
            {
              node: {
                id: convertToGraphQLId('Organization', 2),
                internalId: 2,
                active: true,
                name: 'Apple',
              },
            },
          ],
          totalCount: 1,
        },
        hasSecondaryOrganizations: true,
      },
    })
  })

  it('shows editing/app indicator icons', async () => {
    const wrapper = renderTicketLiveUsers()

    const customerAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(queryByIconName(customerAvatar.parentElement!, 'pencil')).not.toBeInTheDocument()

    expect(queryByIconName(customerAvatar.parentElement!, 'phone')).not.toBeInTheDocument()

    expect(queryByIconName(customerAvatar.parentElement!, 'phone-pencil')).not.toBeInTheDocument()

    const adminAvatar = wrapper.getByRole('img', {
      name: 'Avatar (Test Admin Agent)',
    })

    expect(getByIconName(adminAvatar.parentElement!, 'pencil')).toBeInTheDocument()

    const agent1Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 1 Test)',
    })

    expect(getByIconName(agent1Avatar.parentElement!, 'phone')).toBeInTheDocument()

    const agent2Avatar = wrapper.getByRole('img', {
      name: 'Avatar (Agent 2 Test)',
    })

    expect(getByIconName(agent2Avatar.parentElement!, 'phone-pencil')).toBeInTheDocument()
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

    expect(getByIconName(customerAvatar.parentElement!, 'user-idle-2')).toHaveClasses([
      'fill-stone-200',
      'dark:fill-neutral-500',
    ])

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

    expect(getByIconName(agent2Avatar.parentElement!, 'phone-pencil')).toHaveClasses([
      'fill-stone-200',
      'dark:fill-neutral-500',
    ])
  })

  describe('Ai Agent', () => {
    it('indicates that agent is processing this ticket', async () => {
      const wrapper = renderTicketLiveUsers(undefined, { aiAgentRunning: true })

      expect(wrapper.getByLabelText('AI Agent')).toBeInTheDocument()
    })
  })
})
