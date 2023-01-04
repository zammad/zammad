// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { OrganizationDocument } from '@mobile/entities/organization/graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '@mobile/entities/organization/graphql/subscriptions/organizationUpdates.api'
import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import type { ConfidentTake } from '@shared/types/utils'
import type { OrganizationQuery } from '@shared/graphql/types'
import { within } from '@testing-library/vue'
import { mockTicketDetailViewGql } from './mocks/detail-view'

const visitTicketOrganization = async (
  organization: ConfidentTake<OrganizationQuery, 'organization'>,
) => {
  mockTicketDetailViewGql()

  const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
    organization,
  })
  const mockSubscription = mockGraphQLSubscription(OrganizationUpdatesDocument)
  const mockAttributes = mockOrganizationObjectAttributes()

  const view = await visitView('/tickets/1/information/organization')

  await waitUntil(() => mockApi.calls.resolve && mockAttributes.calls.resolve)

  const helpers = within(view.container as HTMLElement)

  return {
    view: {
      ...helpers,
      container: view.container,
      events: view.events,
    },
    mockApi,
    mockSubscription,
  }
}

describe('static organization', () => {
  it('shows organization', async () => {
    const organization = defaultOrganization()
    const { view, mockSubscription } = await visitTicketOrganization(
      organization,
    )

    expect(view.getByText(organization.name || 'unknown')).toBeInTheDocument()

    expect(view.getByRole('region', { name: 'Note' })).toHaveTextContent(
      'Save something as this note',
    )

    expect(
      view.getByRole('button', { name: 'Edit Organization' }),
    ).toBeInTheDocument()

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
    const organization = defaultOrganization()
    const { view, mockApi } = await visitTicketOrganization({
      ...organization,
      members: {
        ...organization.members,
        edges: organization.members?.edges || [],
        totalCount: 2,
      },
    })

    expect(view.container).toHaveTextContent('Members')

    const members = organization.members?.edges || []

    expect(members).toHaveLength(1)
    expect(view.container).toHaveTextContent(members[0].node.fullname!)

    mockApi.spies.resolve.mockResolvedValue({
      data: {
        organization: {
          ...organization,
          members: {
            ...organization.members,
            edges: [
              ...members,
              {
                __typename: 'UserEdge',
                node: {
                  __typename: 'User',
                  id: 'dsa214dascxasdw',
                  internalId: 2,
                  firstname: 'Jane',
                  vip: false,
                  lastname: 'Hunter',
                  fullname: 'Jane Hunter',
                  image: null,
                },
              },
            ],
          },
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Show 1 more' }))
    await waitUntil(() => mockApi.calls.resolve > 1)

    expect(view.container).toHaveTextContent('Jane Hunter')
  })

  it('cannot edit organization without permission', async () => {
    const organization = defaultOrganization()
    organization.policy = {
      update: false,
      __typename: 'Policy',
    }
    const { view } = await visitTicketOrganization(organization)

    expect(
      view.queryByRole('button', { name: 'Edit Organization' }),
    ).not.toBeInTheDocument()
  })
})
