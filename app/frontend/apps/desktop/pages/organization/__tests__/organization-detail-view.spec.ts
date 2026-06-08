// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { capitalize } from 'lodash-es'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTicketStateTypeCategory,
  type Organization,
  type UserEdge,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketsByOrganizationQuery,
  waitForTicketsByOrganizationQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsByOrganization.mocks.ts'
import { waitForTicketsStatsMonthlyByOrganizationQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsStatsMonthlyByOrganization.mocks.ts'
import { getTicketByOrganizationUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/ticketByOrganizationUpdates.mocks.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const organizationData: Organization = {
  id: convertToGraphQLId('Organization', 1),
  internalId: 1,
  name: 'Zammad Foundation',
  shared: true,
  domain: '',
  domainAssignment: false,
  active: true,
  note: '<p dir="auto">note test</p><p dir="auto"></p>',
  vip: false,
  objectAttributeValues: [],
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
  createdBy: null,
  updatedBy: null,
  __typename: 'Organization',
  allMembers: {
    edges: [],
    pageInfo: {
      endCursor: 'MQ',
      hasNextPage: false,
      hasPreviousPage: false,
      __typename: 'PageInfo',
    },
    totalCount: 0,
    __typename: 'UserConnection',
  },
  policy: {
    update: true,
    destroy: true,
    __typename: 'PolicyDefault',
  },
  ticketsCount: {
    open: 11,
    closed: 6,
    openSearchQuery: 'openSearchQuery',
    closedSearchQuery: 'closedSearchQuery',
    __typename: 'TicketCount',
  },
}

const userEdges: UserEdge[] = [
  {
    cursor: 'MQ',
    __typename: 'UserEdge',
    node: {
      __typename: 'User',
      id: convertToGraphQLId('User', 1),
      internalId: 1,
      fullname: 'User 1',
      active: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      policy: { update: true, destroy: true, __typename: 'PolicyDefault' },
    },
  },
  {
    cursor: 'MQ',
    __typename: 'UserEdge',
    node: {
      __typename: 'User',
      id: convertToGraphQLId('User', 2),
      internalId: 2,
      fullname: 'User 2',
      active: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      policy: { update: true, destroy: true, __typename: 'PolicyDefault' },
    },
  },
  {
    cursor: 'MQ',
    __typename: 'UserEdge',
    node: {
      __typename: 'User',
      id: convertToGraphQLId('User', 3),
      internalId: 3,
      fullname: 'User 3',
      active: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      policy: { update: true, destroy: true, __typename: 'PolicyDefault' },
    },
  },
  {
    cursor: 'MQ',
    __typename: 'UserEdge',
    node: {
      __typename: 'User',
      id: convertToGraphQLId('User', 4),
      internalId: 4,
      fullname: 'User 4',
      active: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      policy: { update: true, destroy: true, __typename: 'PolicyDefault' },
    },
  },
  {
    cursor: 'MQ',
    __typename: 'UserEdge',
    node: {
      __typename: 'User',
      id: convertToGraphQLId('User', 5),
      internalId: 5,
      fullname: 'User 5',
      active: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      policy: { update: true, destroy: true, __typename: 'PolicyDefault' },
    },
  },
]

const visitOrganizationView = async () => {
  const view = await visitView(`/organizations/${organizationData.internalId}`)

  const main = view.getByRole('main')
  const header = within(main).getByTestId('organization-detail-top-bar')

  return { view, main, header }
}

describe('Organization Detail View', () => {
  beforeEach(async () => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
    })

    mockPermissions(['ticket.agent'])

    mockOrganizationQuery({
      organization: organizationData,
    })
  })

  describe('displays breadcrumb navigation', () => {
    it('displays breadcrumb navigation', async () => {
      const { header } = await visitOrganizationView()

      const breadcrumb = within(header).getByRole('navigation', { name: 'Breadcrumb navigation' })
      const items = within(breadcrumb).getAllByRole('listitem')

      expect(items).toHaveLength(2)
      expect(items[0]).toHaveTextContent('Organization')
      expect(within(items[1]).getByRole('heading')).toHaveAccessibleName('Zammad Foundation')
    })

    it('copies organization name', async () => {
      const { view, header } = await visitOrganizationView()

      const breadcrumb = within(header).getByRole('navigation', { name: 'Breadcrumb navigation' })

      await view.events.click(
        within(breadcrumb).getByRole('button', { name: 'Copy organization display name' }),
      )

      expect(copyToClipboardMock).toHaveBeenCalledWith([
        {
          data: {
            'text/html':
              '<a href="http://zammad.example.com/desktop/organizations/1">Zammad Foundation</a>',
            'text/plain': 'Zammad Foundation',
          },
          options: {
            presentationStyle: 'unspecified',
          },
        },
      ])
    })

    it('displays basic organization information', async () => {
      const { header } = await visitOrganizationView()

      expect(within(header).getByLabelText('Avatar (Zammad Foundation)')).toBeVisible()
      expect(within(header).getByText('Zammad Foundation', { selector: 'span' })).toBeVisible()
    })

    it('displays actions for agent users', async () => {
      mockPermissions(['ticket.agent'])

      const { view, header } = await visitOrganizationView()

      expect(within(header).getByRole('menuitem', { name: 'New user' })).toBeVisible()

      await view.events.click(within(header).getByRole('button', { name: 'Action menu button' }))

      const actionPopover = await view.findByRole('region', { name: 'Action menu button' })

      expect(within(actionPopover).getByRole('menuitem', { name: 'Edit' })).toBeVisible()
      expect(within(actionPopover).getByRole('menuitem', { name: 'History' })).toBeVisible()
    })

    it('displays actions for admin users', async () => {
      mockPermissions(['admin.organization', 'admin.user'])

      const { view, header } = await visitOrganizationView()

      expect(within(header).getByRole('menuitem', { name: 'New user' })).toBeVisible()

      await view.events.click(within(header).getByRole('button', { name: 'Action menu button' }))

      const actionPopover = await view.findByRole('region', { name: 'Action menu button' })

      expect(within(actionPopover).getByRole('menuitem', { name: 'Edit' })).toBeVisible()

      expect(within(actionPopover).getByRole('menuitem', { name: 'History' })).toBeVisible()
    })
  })

  describe('Object attributes', () => {
    it('displays organization attributes', async () => {
      const { main } = await visitOrganizationView()

      expect(within(main).getByText('Shared organization').parentElement).toHaveTextContent('yes')
      expect(within(main).getByText('Domain based assignment').parentElement).toHaveTextContent(
        'no',
      )
    })
  })

  describe('Organization members', () => {
    it('hides section when organization has no members', async () => {
      const { main } = await visitOrganizationView()

      expect(within(main).queryByRole('region', { name: 'Members' })).not.toBeInTheDocument()
    })

    it('displays section when organization has some members', async () => {
      const organizationWithMembers: Organization = {
        ...organizationData,
        allMembers: {
          edges: userEdges.slice(0, 2),
          pageInfo: {
            endCursor: 'Mx',
            hasNextPage: false,
            hasPreviousPage: false,
            __typename: 'PageInfo',
          },
          totalCount: 2,
          __typename: 'UserConnection',
        },
      }

      mockOrganizationQuery({ organization: organizationWithMembers })

      const { main } = await visitOrganizationView()

      const container = within(main).getByRole('region', { name: 'Members' })

      expect(within(container).getByRole('heading', { name: 'Members' })).toHaveTextContent('2')

      await waitFor(() => {
        expect(within(container).getByText('User 1')).toBeInTheDocument()
        expect(within(container).getByText('User 2')).toBeInTheDocument()
      })
    })

    it('supports fetching more members', async () => {
      const organizationWithMembers: Organization = {
        ...organizationData,
        allMembers: {
          edges: userEdges.slice(0, 4),
          pageInfo: {
            endCursor: 'Mx',
            hasNextPage: true,
            hasPreviousPage: false,
            __typename: 'PageInfo',
          },
          totalCount: 5,
          __typename: 'UserConnection',
        },
      }

      mockOrganizationQuery({ organization: organizationWithMembers })

      const { main, view } = await visitOrganizationView()

      const container = within(main).getByRole('region', { name: 'Members' })

      expect(within(container).getByRole('heading', { name: 'Members' })).toHaveTextContent('5')

      await waitFor(() => {
        expect(within(container).getByText('User 1')).toBeInTheDocument()
        expect(within(container).getByText('User 2')).toBeInTheDocument()
        expect(within(container).getByText('User 3')).toBeInTheDocument()
        expect(within(container).getByText('User 4')).toBeInTheDocument()

        expect(within(container).queryByText('User 5')).not.toBeInTheDocument()

        expect(within(container).getByRole('button', { name: 'Show more' })).toBeInTheDocument()
      })

      mockOrganizationQuery({
        organization: {
          ...organizationWithMembers,
          allMembers: {
            edges: userEdges.slice(4),
            pageInfo: {
              endCursor: null,
            },
            totalCount: 5,
          },
        },
      })

      await view.events.click(within(container).getByRole('button', { name: 'Show more' }))

      await waitFor(() => {
        expect(within(container).getByText('User 1')).toBeInTheDocument()
        expect(within(container).getByText('User 2')).toBeInTheDocument()
        expect(within(container).getByText('User 3')).toBeInTheDocument()
        expect(within(container).getByText('User 4')).toBeInTheDocument()
        expect(within(container).getByText('User 5')).toBeInTheDocument()

        expect(
          within(container).queryByRole('button', { name: 'Show more' }),
        ).not.toBeInTheDocument()
      })
    })

    it('redirects to user search with organization filter when clicking search all', async () => {
      const organizationWithMembers: Organization = {
        ...organizationData,
        allMembers: {
          edges: userEdges.slice(0, 4),
          pageInfo: {
            endCursor: 'Mx',
            hasNextPage: true,
            hasPreviousPage: false,
            __typename: 'PageInfo',
          },
          totalCount: 5,
          __typename: 'UserConnection',
        },
      }

      mockOrganizationQuery({ organization: organizationWithMembers })

      const { main, view } = await visitOrganizationView()

      const container = within(main).getByRole('region', { name: 'Members' })

      await view.events.click(within(container).getByRole('button', { name: 'Search all' }))

      await waitFor(() => {
        expect(view.router.currentRoute.value.fullPath).toBe(
          '/search/organization.id:1 OR organizations.id:1?entity=User',
        )
      })
    })
  })

  describe('Organization tickets', () => {
    beforeEach(() => {
      const dummyTickets = Array.from({ length: 7 }, () => createDummyTicket())

      mockTicketsByOrganizationQuery((variables) => {
        const totalCount = variables.stateTypeCategory === EnumTicketStateTypeCategory.Open ? 4 : 3
        const start = variables.stateTypeCategory === EnumTicketStateTypeCategory.Open ? 0 : 3
        const end = totalCount - 1

        return {
          ticketsByOrganization: {
            totalCount,
            edges: dummyTickets.slice(start, end).map((ticket) => ({
              node: ticket,
            })),
          },
        }
      })
    })

    it('displays organization tickets section', async () => {
      const { main } = await visitOrganizationView()

      const calls = await waitForTicketsByOrganizationQueryCalls()

      expect(calls).toHaveLength(2)

      const organizationTicketsSection = within(main).getByRole('region', {
        name: 'Organization tickets',
      })

      expect(
        within(organizationTicketsSection).getByRole('heading', {
          name: 'Organization tickets',
          level: 2,
        }),
      ).toBeVisible()

      const openTicketsHeading = await within(organizationTicketsSection).findByRole('heading', {
        name: 'Open tickets',
      })

      expect(openTicketsHeading).toHaveTextContent('4')

      const closedTicketsHeading = await within(organizationTicketsSection).findByRole('heading', {
        name: 'Closed tickets',
      })

      expect(closedTicketsHeading).toHaveTextContent('3')
    })

    it('refetch tickets when organization subscription triggers', async () => {
      await visitOrganizationView()

      const calls = await waitForTicketsByOrganizationQueryCalls()

      expect(calls).toHaveLength(2)

      await getTicketByOrganizationUpdatesSubscriptionHandler().trigger({
        ticketByOrganizationUpdates: {
          listChanged: true,
        },
      })

      expect(calls).toHaveLength(4)
    })

    it('hides organization tickets section when organization has no tickets', async () => {
      mockOrganizationQuery({
        organization: {
          ...organizationData,
          ticketsCount: {
            open: 0,
            closed: 0,
            openSearchQuery: 'openSearchQuery',
            closedSearchQuery: 'closedSearchQuery',
            __typename: 'TicketCount',
          },
        },
      })

      const { main } = await visitOrganizationView()

      expect(
        within(main).queryByRole('region', {
          name: 'Organization tickets',
        }),
      ).not.toBeInTheDocument()
    })

    it.each(['open', 'closed'])(
      'hides %s tickets section when organization has no such tickets',
      async (state) => {
        mockOrganizationQuery({
          organization: {
            ...organizationData,
            ticketsCount: {
              [state]: 0,
              [state === 'open' ? 'closed' : 'open']: 5,
            },
          },
        })

        const { main } = await visitOrganizationView()

        const calls = await waitForTicketsByOrganizationQueryCalls()

        expect(calls).toHaveLength(1) // the "other" one

        const organizationTicketsSection = within(main).getByRole('region', {
          name: 'Organization tickets',
        })

        expect(
          within(organizationTicketsSection).queryByRole('heading', {
            name: `${capitalize(state)} tickets`,
            level: 3,
          }),
        ).not.toBeInTheDocument()

        waitFor(() => {
          expect(
            within(organizationTicketsSection).queryByRole('heading', {
              name: `${state === 'open' ? 'Closed tickets' : 'Open tickets'}`,
              level: 3,
            }),
          ).toBeVisible()
        })
      },
    )
  })

  describe('Ticket frequency chart', () => {
    it('renders a chart', async () => {
      const { main } = await visitOrganizationView()
      const chart = within(main).getByTestId('chart')

      expect(chart).toBeVisible()
    })

    it('refetch chart data when organization subscription triggers', async () => {
      await visitOrganizationView()

      const calls = await waitForTicketsStatsMonthlyByOrganizationQueryCalls()

      expect(calls).toHaveLength(1)

      await getTicketByOrganizationUpdatesSubscriptionHandler().trigger({
        ticketByOrganizationUpdates: {
          listChanged: true,
        },
      })

      expect(calls).toHaveLength(2)
    })
  })
})
