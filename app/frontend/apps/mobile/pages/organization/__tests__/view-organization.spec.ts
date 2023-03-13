// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockOnlineNotificationSeenGql } from '@shared/composables/__tests__/mocks/online-notification'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { OrganizationDocument } from '@mobile/entities/organization/graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '@mobile/entities/organization/graphql/subscriptions/organizationUpdates.api'
import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { setupView } from '@tests/support/mock-user'

const prepareMocks = () => {
  const organization = defaultOrganization()
  const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
    organization,
  })
  const mockSubscription = mockGraphQLSubscription(OrganizationUpdatesDocument)
  mockOrganizationObjectAttributes()

  return {
    organization,
    mockApi,
    mockSubscription,
  }
}

beforeEach(() => {
  mockOnlineNotificationSeenGql()
})

describe('static organization', () => {
  it('shows organization', async () => {
    mockPermissions(['admin.organization'])

    const { organization, mockApi, mockSubscription } = prepareMocks()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.getByText(organization.name || 'not found')).toBeInTheDocument()

    expect(
      view.getByRole('region', { name: 'Shared organization' }),
    ).toHaveTextContent('no')
    expect(
      view.getByRole('region', { name: 'Domain based assignment' }),
    ).toHaveTextContent('yes')

    expect(view.container).toHaveTextContent('Tickets')

    const openTickets = view.getByRole('link', { name: 'open 3' })
    const closedTickets = view.getByRole('link', { name: 'closed 1' })

    expect(openTickets).toHaveAttribute(
      'href',
      expect.stringContaining(`organization.id: ${organization.internalId}`),
    )
    expect(closedTickets).toHaveAttribute(
      'href',
      expect.stringContaining(`organization.id: ${organization.internalId}`),
    )

    await mockSubscription.next({
      data: {
        organizationUpdates: {
          __typename: 'OrganizationUpdatesPayload',
          organization: {
            ...organization,
            name: 'Updated Organization',
          },
        },
      },
    })

    expect(view.getByText('Updated Organization')).toBeInTheDocument()
  })

  it('shows organization members', async () => {
    mockPermissions(['admin.organization'])

    const organization = defaultOrganization()
    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization: {
        ...organization,
        members: {
          ...organization.members,
          totalCount: 2,
        },
      },
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    mockOrganizationObjectAttributes()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.container).toHaveTextContent('Members')

    const members = organization.members?.edges || []

    expect(members).toHaveLength(1)
    expect(view.container).toHaveTextContent(members[0].node.fullname!)

    const image = Buffer.from('jane.png').toString('base64')
    mockApi.spies.resolve.mockResolvedValue({
      data: {
        organization: {
          ...organization,
          members: {
            ...organization.members,
            edges: nullableMock([
              ...members,
              {
                __typename: 'UserEdge',
                node: {
                  __typename: 'User',
                  id: convertToGraphQLId('User', 300),
                  internalId: 300,
                  vip: true,
                  outOfOffice: false,
                  firstname: 'Jane',
                  lastname: 'Hunter',
                  fullname: 'Jane Hunter',
                  image,
                  active: false,
                },
              },
              {
                __typename: 'UserEdge',
                node: {
                  __typename: 'User',
                  id: convertToGraphQLId('User', 400),
                  internalId: 400,
                  vip: true,
                  outOfOffice: true,
                  firstname: 'Max',
                  lastname: 'Mustermann',
                  fullname: 'Max Mustermann',
                  active: true,
                  image: null,
                },
              },
            ]),
          },
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Show 1 more' }))
    await waitUntil(() => mockApi.calls.resolve > 1)

    const [, JD, JH, MM] = view.getAllByTestId('common-avatar')

    expect(JD).toBeAvatarElement({
      active: true,
      type: 'user',
    })

    expect(JH).toBeAvatarElement({
      active: false,
      image,
      vip: true,
      type: 'user',
    })

    expect(MM).toBeAvatarElement({
      vip: true,
      outOfOffice: true,
      type: 'user',
    })

    expect(view.container).toHaveTextContent(members[0].node.fullname!)
    expect(view.container).toHaveTextContent('Jane Hunter')
  })

  it('can edit organization with required update policy', async () => {
    const organization = defaultOrganization()
    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization,
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    mockOrganizationObjectAttributes()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.getByRole('button', { name: 'Edit' })).toBeInTheDocument()
  })

  it('cannot edit organization without required update policy', async () => {
    const organization = defaultOrganization()
    organization.policy.update = false

    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization,
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    mockOrganizationObjectAttributes()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.queryByRole('button', { name: 'Edit' })).not.toBeInTheDocument()
  })

  it('redirects to error page if organization is not found', async () => {
    mockPermissions(['admin.organization'])

    const mockApi =
      mockGraphQLApi(OrganizationDocument).willFailWithNotFoundError()
    mockOrganizationObjectAttributes()

    const view = await visitView('/organizations/123')

    await waitUntil(() => mockApi.calls.error)

    await expect(view.findByText('Not found')).resolves.toBeInTheDocument()
  })

  it('redirects to error page if access to organization is forbidden', async () => {
    mockPermissions(['admin.organization'])

    const mockApi =
      mockGraphQLApi(OrganizationDocument).willFailWithForbiddenError()
    mockOrganizationObjectAttributes()

    const view = await visitView('/organizations/123')

    await waitUntil(() => mockApi.calls.error)

    await expect(view.findByText('Forbidden')).resolves.toBeInTheDocument()
  })
})

test('correctly redirects from organization hash-based routes', async () => {
  setupView('agent')
  prepareMocks()
  await visitView('/#organization/profile/1')
  const router = getTestRouter()
  const route = router.currentRoute.value
  expect(route.name).toBe('OrganizationDetailView')
  expect(route.params).toEqual({ internalId: '1' })
})
