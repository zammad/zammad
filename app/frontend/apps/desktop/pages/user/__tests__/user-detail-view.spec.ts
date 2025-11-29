// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'
import type { OrganizationEdge, User } from '#shared/graphql/types.ts'

import { waitForCustomerTicketsByFilterQueryCalls } from '#desktop/entities/ticket/graphql/queries/customerTicketsByFilter.mocks.ts'
import { waitForTicketsStatsMonthlyByCustomerQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsStatsMonthlyByCustomer.mocks.ts'
import { getCustomerTicketsByFilterUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/customerTicketsByFilterUpdates.mocks.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const user: User = {
  __typename: 'User',
  id: 'gid://zammad/User/2',
  internalId: 2,
  firstname: 'Nicole',
  lastname: 'Braun',
  fullname: 'Nicole Braun',
  email: 'nicole.braun@zammad.org',
  organization: {
    __typename: 'Organization',
    id: 'gid://zammad/Organization/1',
    internalId: 1,
    name: 'Zammad Foundation',
    active: true,
    policy: {
      update: true,
      destroy: true,
    },
    createdAt: '2020-01-01T12:00:00Z',
    updatedAt: '2020-01-01T12:00:00Z',
  },
  phone: '+49 123 4567890',
  mobile: '+49 987 6543210',
  image: null,
  vip: false,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  hasSecondaryOrganizations: false,
  active: true,
  policy: {
    update: true,
    destroy: true,
  },
  ticketsCount: {
    __typename: 'TicketCount',
    open: 5,
    closed: 10,
    organizationOpen: 15,
    organizationClosed: 20,
  },
  createdAt: '2020-01-01T12:00:00Z',
  updatedAt: '2020-01-01T12:00:00Z',
}

const secondaryOrganizationEdges: OrganizationEdge[] = [
  {
    __typename: 'OrganizationEdge',
    node: {
      __typename: 'Organization',
      id: 'gid://zammad/Organization/2',
      internalId: 2,
      name: 'Secondary Org 1',
      active: true,
      policy: {
        update: true,
        destroy: true,
      },
      createdAt: '2020-01-02T12:00:00Z',
      updatedAt: '2020-01-02T12:00:00Z',
    },
    cursor: 'Mw',
  },
  {
    __typename: 'OrganizationEdge',
    node: {
      __typename: 'Organization',
      id: 'gid://zammad/Organization/3',
      internalId: 3,
      name: 'Secondary Org 2',
      active: true,
      policy: {
        update: true,
        destroy: true,
      },
      createdAt: '2020-01-02T12:00:00Z',
      updatedAt: '2020-01-02T12:00:00Z',
    },
    cursor: 'Mw',
  },
  {
    __typename: 'OrganizationEdge',
    node: {
      __typename: 'Organization',
      id: 'gid://zammad/Organization/4',
      internalId: 4,
      name: 'Secondary Org 3',
      active: true,
      policy: {
        update: true,
        destroy: true,
      },
      createdAt: '2020-01-02T12:00:00Z',
      updatedAt: '2020-01-02T12:00:00Z',
    },
    cursor: 'Mw',
  },
  {
    __typename: 'OrganizationEdge',
    node: {
      __typename: 'Organization',
      id: 'gid://zammad/Organization/5',
      internalId: 5,
      name: 'Secondary Org 4',
      active: true,
      policy: {
        update: true,
        destroy: true,
      },
      createdAt: '2020-01-02T12:00:00Z',
      updatedAt: '2020-01-02T12:00:00Z',
    },
    cursor: 'Mw',
  },
  {
    __typename: 'OrganizationEdge',
    node: {
      __typename: 'Organization',
      id: 'gid://zammad/Organization/6',
      internalId: 6,
      name: 'Secondary Org 5',
      active: true,
      policy: {
        update: true,
        destroy: true,
      },
      createdAt: '2020-01-02T12:00:00Z',
      updatedAt: '2020-01-02T12:00:00Z',
    },
    cursor: 'Mw',
  },
]

describe('User Detail View', () => {
  beforeEach(() => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
    })

    mockPermissions(['ticket.agent'])
    mockUserQuery({ user })
  })

  describe('Top information bar', () => {
    it('displays breadcrumb navigation', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')
      const header = within(main).getByTestId('user-detail-top-bar')
      const breadcrumb = within(header).getByRole('navigation', { name: 'Breadcrumb navigation' })
      const items = within(breadcrumb).getAllByRole('listitem')

      expect(items).toHaveLength(2)
      expect(items[0]).toHaveTextContent('User')
      expect(within(items[1]).getByRole('heading')).toHaveAccessibleName('Nicole Braun')
    })

    it('copies user name', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')
      const header = within(main).getByTestId('user-detail-top-bar')
      const breadcrumb = within(header).getByRole('navigation', { name: 'Breadcrumb navigation' })

      await view.events.click(
        within(breadcrumb).getByRole('button', { name: 'Copy user display name' }),
      )

      expect(copyToClipboardMock).toHaveBeenCalledWith([
        {
          data: {
            'text/html': '<a href="http://zammad.example.com/desktop/users/2">Nicole Braun</a>',
            'text/plain': 'Nicole Braun',
          },
          options: {
            presentationStyle: 'unspecified',
          },
        },
      ])
    })

    it('displays basic user information', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')
      const header = within(main).getByTestId('user-detail-top-bar')

      expect(within(header).getByLabelText('Avatar (Nicole Braun)')).toHaveTextContent('NB')
      expect(within(header).getByText('Nicole Braun', { selector: 'span' })).toBeVisible()
      expect(within(header).getByText('Zammad Foundation')).toBeVisible()
    })
  })

  describe('Secondary organizations', () => {
    it('hides section when user has no secondary organizations', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')

      expect(
        within(main).queryByRole('region', { name: 'Secondary organizations' }),
      ).not.toBeInTheDocument()
    })

    it('displays section when user has some secondary organizations', async () => {
      const userWithSecondaryOrganizations: User = {
        ...user,
        hasSecondaryOrganizations: true,
        secondaryOrganizations: {
          edges: secondaryOrganizationEdges.slice(0, 2),
          pageInfo: {
            endCursor: 'Mw',
            hasNextPage: false,
            hasPreviousPage: false,
          },
          totalCount: 2,
        },
      }

      mockUserQuery({ user: userWithSecondaryOrganizations })

      const view = await visitView('/users/2')

      const main = view.getByRole('main')

      const container = within(main).getByRole('region', { name: 'Secondary organizations' })

      expect(
        within(container).getByRole('heading', { name: 'Secondary organizations' }),
      ).toHaveTextContent('2')

      waitFor(() => {
        expect(within(container).getByText('Secondary Org 1')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 2')).toBeInTheDocument()
      })
    })

    it('supports fetching more secondary organizations', async () => {
      const userWithSecondaryOrganizations: User = {
        ...user,
        hasSecondaryOrganizations: true,
        secondaryOrganizations: {
          edges: secondaryOrganizationEdges.slice(0, 4),
          pageInfo: {
            endCursor: 'Mw',
            hasNextPage: true,
            hasPreviousPage: false,
          },
          totalCount: 5,
        },
      }

      mockUserQuery({ user: userWithSecondaryOrganizations })

      const view = await visitView('/users/2')

      const main = view.getByRole('main')

      const container = within(main).getByRole('region', { name: 'Secondary organizations' })

      expect(
        within(container).getByRole('heading', { name: 'Secondary organizations' }),
      ).toHaveTextContent('5')

      waitFor(() => {
        expect(within(container).getByText('Secondary Org 1')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 2')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 3')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 4')).toBeInTheDocument()

        expect(within(container).queryByText('Secondary Org 5')).not.toBeInTheDocument()

        expect(within(container).getByRole('button', { name: 'Show more' })).toBeInTheDocument()
      })

      mockUserQuery({
        user: {
          ...userWithSecondaryOrganizations,
          secondaryOrganizations: {
            edges: secondaryOrganizationEdges.slice(4),
            pageInfo: {
              endCursor: null,
            },
            totalCount: 5,
          },
        },
      })

      await view.events.click(within(container).getByRole('button', { name: 'Show more' }))

      waitFor(() => {
        expect(within(container).getByText('Secondary Org 1')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 2')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 3')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 4')).toBeInTheDocument()
        expect(within(container).getByText('Secondary Org 5')).toBeInTheDocument()

        expect(
          within(container).queryByRole('button', { name: 'Show more' }),
        ).not.toBeInTheDocument()
      })
    })
  })

  describe('Object attributes', () => {
    it('displays user attributes', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')

      expect(within(main).getByText('Email').parentElement).toHaveTextContent(
        'nicole.braun@zammad.org',
      )
      expect(within(main).getByText('Phone').parentElement).toHaveTextContent('+49 123 4567890')
      expect(within(main).getByText('Mobile').parentElement).toHaveTextContent('+49 987 6543210')
    })
  })

  describe('Related tickets', () => {
    it('displays related tickets section', async () => {
      const view = await visitView('/users/2')

      const calls = await waitForCustomerTicketsByFilterQueryCalls()

      expect(calls).toHaveLength(2)

      const main = view.getByRole('main')
      const relatedTicketsSection = within(main).getByRole('region', { name: 'Related tickets' })

      expect(
        within(relatedTicketsSection).getByRole('heading', { name: 'Related tickets', level: 2 }),
      ).toBeVisible()

      expect(within(relatedTicketsSection).getAllByRole('tab')).toHaveLength(2)

      const userTab = within(relatedTicketsSection).getByRole('tab', { name: 'User' })

      expect(userTab).toHaveTextContent('15')
      expect(userTab).toHaveAttribute('aria-selected', 'true')

      const organizationTab = within(relatedTicketsSection).getByRole('tab', {
        name: 'Organization',
      })

      expect(organizationTab).toHaveTextContent('35')
      expect(organizationTab).not.toHaveAttribute('aria-selected', 'true')

      await view.events.click(organizationTab)

      expect(userTab).not.toHaveAttribute('aria-selected', 'true')
      expect(organizationTab).toHaveAttribute('aria-selected', 'true')

      expect(calls).toHaveLength(4)
    })

    it('refetch related tickets when user subscription triggers', async () => {
      await visitView('/users/2')

      const calls = await waitForCustomerTicketsByFilterQueryCalls()

      expect(calls).toHaveLength(2)

      await getCustomerTicketsByFilterUpdatesSubscriptionHandler().trigger({
        ticketCustomerTicketsByFilterUpdates: {
          listChanged: true,
        },
      })

      expect(calls).toHaveLength(4)
    })
  })

  describe('Ticket frequency', () => {
    it('renders a chart', async () => {
      const view = await visitView('/users/2')

      const main = view.getByRole('main')
      const chart = within(main).getByTestId('chart')

      expect(chart).toBeVisible()
    })

    it('refetch chart data when user subscription triggers', async () => {
      await visitView('/users/2')

      const calls = await waitForTicketsStatsMonthlyByCustomerQueryCalls()

      expect(calls).toHaveLength(1)

      await getCustomerTicketsByFilterUpdatesSubscriptionHandler().trigger({
        ticketCustomerTicketsByFilterUpdates: {
          listChanged: true,
        },
      })

      expect(calls).toHaveLength(2)
    })
  })
})
