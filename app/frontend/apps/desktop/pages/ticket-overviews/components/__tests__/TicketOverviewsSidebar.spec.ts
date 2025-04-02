// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentTicketOverviewsQuery } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'
import TicketOverviewsSidebar from '#desktop/pages/ticket-overviews/components/TicketOverviewsSidebar.vue'

const renderSidebar = () =>
  renderComponent(TicketOverviewsSidebar, {
    router: true,
  })

describe('TicketOverviewsSidebar', () => {
  beforeEach(() => {
    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: [
        {
          id: convertToGraphQLId('Overview', 1),
          name: 'My Assigned Tickets',
          link: 'my_assigned',
          prio: 1000,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
          active: true,
          ticketCount: 2,
        },
        {
          id: convertToGraphQLId('Overview', 2),
          name: 'Unassigned & Open Tickets',
          link: 'all_unassigned',
          prio: 1010,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
          active: true,
          ticketCount: 12,
        },
      ],
    })
  })

  it('hides reorder items if user is has not overview sorting preference', () => {
    const wrapper = renderSidebar()

    expect(
      wrapper.queryByRole('link', { name: 'reorder items' }),
    ).not.toBeInTheDocument()
  })

  it('displays link which redirects to personal settings overview', async () => {
    const wrapper = renderSidebar()

    mockPermissions(['user_preferences.overview_sorting'])

    expect(await wrapper.findByRole('link')).toHaveTextContent('reorder items')
    expect(wrapper.getByRole('link')).toHaveAttribute(
      'href',
      '/desktop/personal-setting/ticket-overviews',
    )

    expect(wrapper.getByIconName('list-columns-reverse')).toBeInTheDocument()
  })

  it('displays overview items', async () => {
    const wrapper = renderSidebar()

    expect(await wrapper.findByText('My Assigned Tickets')).toBeInTheDocument()
    expect(wrapper.getByText('Unassigned & Open Tickets')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'My Assigned Tickets' }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Unassigned & Open Tickets' }),
    ).toBeInTheDocument()
  })
})
