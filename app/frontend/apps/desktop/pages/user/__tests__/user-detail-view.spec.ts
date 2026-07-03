// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { capitalize } from 'lodash-es'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'
import type { OrganizationEdge, User } from '#shared/graphql/types.ts'

import { waitForTicketsByCustomerQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsByCustomer.mocks.ts'
import { waitForTicketsStatsMonthlyByCustomerQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsStatsMonthlyByCustomer.mocks.ts'
import { getTicketByCustomerUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/ticketByCustomerUpdates.mocks.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const scrollIntoViewMock = vi.fn()

vi.mock('#shared/utils/dom.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/dom.ts')>()),
  scrollIntoView: scrollIntoViewMock,
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
  source: 'signup',
  verified: false,
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
  })

  describe('with default user', () => {
    beforeEach(() => {
      mockUserQuery({ user })
    })

    describe('Top information bar', () => {
      it('displays breadcrumb navigation', async () => {
        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const header = within(main).getByTestId('user-detail-top-bar-full-details')
        const breadcrumb = within(header).getByRole('navigation', { name: 'Breadcrumb navigation' })
        const items = within(breadcrumb).getAllByRole('listitem')

        expect(items).toHaveLength(2)
        expect(items[0]).toHaveTextContent('User')
        expect(within(items[1]).getByRole('heading')).toHaveAccessibleName('Nicole Braun')
      })

      it('copies user name', async () => {
        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const header = within(main).getByTestId('user-detail-top-bar-full-details')
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
        const header = within(main).getByTestId('user-detail-top-bar-full-details')

        expect(within(header).getByLabelText('Avatar (Nicole Braun)')).toHaveTextContent('NB')
        expect(within(header).getByText('Nicole Braun', { selector: 'span' })).toBeVisible()
        expect(within(header).getByText('Zammad Foundation')).toBeVisible()
      })

      it('displays actions for agent users', async () => {
        mockPermissions(['ticket.agent'])

        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const header = within(main).getByTestId('user-detail-top-bar-full-details')

        expect(within(header).getByRole('button', { name: 'New ticket' })).toBeVisible()

        await view.events.click(within(header).getByRole('button', { name: 'Additional actions' }))

        const actionPopover = await view.findByRole('region', { name: 'Additional actions' })

        expect(within(actionPopover).getByRole('button', { name: 'Edit' })).toBeVisible()
        expect(within(actionPopover).getByRole('button', { name: 'History' })).toBeVisible()
        expect(within(header).queryByRole('button', { name: 'Delete' })).not.toBeInTheDocument()
      })

      it('displays actions for admin users', async () => {
        mockPermissions(['admin.data_privacy', 'admin.user'])

        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const header = within(main).getByTestId('user-detail-top-bar-full-details')

        await view.events.click(within(header).getByRole('button', { name: 'Additional actions' }))

        const actionPopover = await view.findByRole('region', { name: 'Additional actions' })
        expect(within(actionPopover).getByRole('menuitem', { name: 'Delete' })).toBeVisible()
      })

      it('displays additional actions on some user profiles', async () => {
        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const header = within(main).getByTestId('user-detail-top-bar-full-details')

        await view.events.click(within(header).getByRole('button', { name: 'Additional actions' }))

        const actionPopover = await view.findByRole('region', { name: 'Additional actions' })

        expect(
          within(actionPopover).getByRole('menuitem', { name: 'Resend verification email' }),
        ).toBeVisible()
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

        await waitFor(() => {
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

        await waitFor(() => {
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

        await waitFor(() => {
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

        const calls = await waitForTicketsByCustomerQueryCalls()

        // Both tabs mount immediately (v-show), so all 4 queries fire on load.
        expect(calls).toHaveLength(4)

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
      })

      it('refetch related tickets when user subscription triggers', async () => {
        await visitView('/users/2')

        const calls = await waitForTicketsByCustomerQueryCalls()

        const callCountBeforeRefetch = calls.length

        await getTicketByCustomerUpdatesSubscriptionHandler().trigger({
          ticketByCustomerUpdates: {
            listChanged: true,
          },
        })

        // All 4 ticket lists (open + closed for both user and organization tab) refetch.
        expect(calls).toHaveLength(callCountBeforeRefetch + 4)
      })

      it('hides organization section when user has no organization', async () => {
        const newUser = { ...user, organization: null }

        mockUserQuery({ user: newUser })

        const view = await visitView('/users/2')

        const calls = await waitForTicketsByCustomerQueryCalls()

        expect(calls).toHaveLength(2)

        const main = view.getByRole('main')
        const relatedTicketsSection = within(main).getByRole('region', { name: 'Related tickets' })

        expect(within(relatedTicketsSection).queryAllByRole('tab')).toHaveLength(0)
        expect(within(relatedTicketsSection).queryByText('User')).not.toBeInTheDocument()
        expect(within(relatedTicketsSection).queryByText('Organization')).not.toBeInTheDocument()
      })

      it('hides related tickets section when user has no tickets', async () => {
        const newUser = {
          ...user,
          ticketsCount: {
            open: 0,
            closed: 0,
            organizationOpen: 0,
            organizationClosed: 0,
          },
        }

        mockUserQuery({ user: newUser })

        const view = await visitView('/users/2')

        const main = view.getByRole('main')

        expect(
          within(main).queryByRole('region', { name: 'Related tickets' }),
        ).not.toBeInTheDocument()
      })

      it.each(['open', 'closed'])(
        'hides %s tickets section when user has no such tickets',
        async (state) => {
          const newUser = {
            ...user,
            organization: null,
            ticketsCount: {
              [state]: 0,
              [state === 'open' ? 'closed' : 'open']: 5,
            },
          }

          mockUserQuery({ user: newUser })

          const view = await visitView('/users/2')

          const calls = await waitForTicketsByCustomerQueryCalls()

          expect(calls).toHaveLength(1) // the "other" one

          const main = view.getByRole('main')
          const relatedTicketsSection = within(main).getByRole('region', {
            name: 'Related tickets',
          })

          expect(
            within(relatedTicketsSection).queryByRole('heading', {
              name: `${capitalize(state)} tickets`,
              level: 3,
            }),
          ).not.toBeInTheDocument()

          expect(
            within(relatedTicketsSection).queryByRole('heading', {
              name: `${state === 'open' ? 'Closed tickets' : 'Open tickets'}`,
              level: 3,
            }),
          ).toBeVisible()
        },
      )
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

        await getTicketByCustomerUpdatesSubscriptionHandler().trigger({
          ticketByCustomerUpdates: {
            listChanged: true,
          },
        })

        expect(calls).toHaveLength(2)
      })
    })

    describe('Floating toolbar', () => {
      it('scrolls the content container when scroll actions are clicked', async () => {
        vi.stubGlobal('VITE_TEST_MODE', false)

        const view = await visitView('/users/2')

        const main = view.getByRole('main')
        const toolbar = within(main).getByRole('toolbar', { name: 'Scroll actions' })

        await view.events.click(within(toolbar).getByRole('button', { name: 'Scroll to end' }))

        expect(scrollIntoViewMock).toHaveBeenLastCalledWith(expect.anything(), 'end', {
          behavior: 'auto',
        })

        await view.events.click(within(toolbar).getByRole('button', { name: 'Scroll to start' }))

        expect(scrollIntoViewMock).toHaveBeenLastCalledWith(expect.anything(), 'start', {
          behavior: 'auto',
        })
      })
    })
  })
})
