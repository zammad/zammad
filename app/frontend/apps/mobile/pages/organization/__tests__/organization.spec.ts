// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { nullableMock, waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import { OrganizationDocument } from '#shared/entities/organization/graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '#shared/entities/organization/graphql/subscriptions/organizationUpdates.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'

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

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-11-11T00:00:00Z'))
})

describe('static organization', () => {
  it('shows organization', async () => {
    mockPermissions(['admin.organization'])

    const { organization, mockApi, mockSubscription } = prepareMocks()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.getByText(organization.name || 'Not Found')).toBeInTheDocument()

    expect(
      view.getByLabelText(`Avatar (${organization.name})`),
    ).toBeAvatarElement({
      vip: !!organization.vip,
      active: !!organization.active,
      type: 'organization',
    })

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
    organization.vip = true
    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization: {
        ...organization,
        allMembers: {
          ...organization.allMembers,
          totalCount: 2,
        },
      },
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    mockOrganizationObjectAttributes()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    expect(
      view.getByLabelText(`Avatar (${organization.name})`),
      'renders vip status correctly',
    ).toBeAvatarElement({
      vip: true,
      type: 'organization',
    })

    expect(view.container).toHaveTextContent('Members')

    const members = organization.allMembers?.edges || []

    expect(members).toHaveLength(1)
    expect(view.container).toHaveTextContent(members[0].node.fullname!)

    const image = Buffer.from('jane.png').toString('base64')
    mockApi.spies.resolve.mockResolvedValue({
      data: {
        organization: {
          ...organization,
          allMembers: {
            ...organization.allMembers,
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
                  outOfOfficeStartAt: null,
                  outOfOfficeEndAt: null,
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
                  outOfOfficeStartAt: '2024-11-10',
                  outOfOfficeEndAt: '2024-11-20',
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

    mockGraphQLSubscription(OrganizationUpdatesDocument)

    mockOrganizationObjectAttributes()

    const view = await visitView('/organizations/123')

    await waitUntil(() => mockApi.calls.error)

    await expect(view.findByText('Not Found')).resolves.toBeInTheDocument()
  })

  it('redirects to error page if access to organization is forbidden', async () => {
    mockPermissions(['admin.organization'])

    const mockApi =
      mockGraphQLApi(OrganizationDocument).willFailWithForbiddenError()
    mockGraphQLSubscription(OrganizationUpdatesDocument)
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
