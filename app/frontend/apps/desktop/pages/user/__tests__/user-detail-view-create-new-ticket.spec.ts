// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockUserQuery } from '#shared/entities/user/graphql/queries/user.mocks.ts'
import type { User } from '#shared/graphql/types.ts'

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

describe('User detail view: Create new ticket', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockUserQuery({ user })
  })

  it('redirects to ticket create screen with customer pre-population', async () => {
    mockPermissions(['ticket.agent'])

    const view = await visitView('/users/2')

    const main = view.getByRole('main')
    const header = within(main).getByTestId('user-detail-top-bar')

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            options: [
              {
                value: 1,
                label: 'Users',
              },
              {
                value: 2,
                label: 'some group1',
              },
            ],
          },
          priority_id: {
            options: [
              { value: 1, label: '1 low' },
              { value: 2, label: '2 normal' },
              { value: 3, label: '3 high' },
            ],
          },
          state_id: {
            options: [
              { value: 4, label: 'closed' },
              { value: 1, label: 'new' },
              { value: 2, label: 'open' },
              { value: 6, label: 'pending close' },
              { value: 3, label: 'pending reminder' },
            ],
          },
          pending_time: {
            show: false,
          },
          customer_id: {
            value: '2',
          },
        },
      },
    })

    await view.events.click(within(header).getByRole('menuitem', { name: 'New ticket' }))

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        meta: expect.objectContaining({
          initial: true,
          additionalData: expect.objectContaining({
            customer_id: '2',
          }),
        }),
      }),
    )

    expect(getTestRouter().currentRoute.value.path.startsWith('/tickets/create')).toBe(true)
  })
})
