// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

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

describe('User detail view: Delete user', () => {
  beforeEach(() => {
    mockPermissions(['admin.user'])
    mockUserQuery({ user })

    Object.defineProperty(window, 'location', {
      value: {
        ...window.location,
        pathname: '/desktop',
        href: '/desktop',
      },
    })
  })

  it('redirects to admin data privacy panel with customer pre-population', async () => {
    const view = await visitView('/users/2')

    const main = view.getByRole('main')
    const header = within(main).getByTestId('user-detail-top-bar')

    await view.events.click(within(header).getByRole('button', { name: 'Action menu button' }))

    const popover = await view.findByRole('region', { name: 'Action menu button' })

    await view.events.click(within(popover).getByRole('button', { name: 'Delete' }))

    expect(window.location.href).toBe('/#system/data_privacy/2')
  })
})
