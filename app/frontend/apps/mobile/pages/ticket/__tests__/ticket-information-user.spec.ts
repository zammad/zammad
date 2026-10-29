// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitUntilApisResolved } from '#tests/support/utils.ts'

import type { UserQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'
import { SYSTEM_USER_ID, SYSTEM_USER_INTERNAL_ID } from '#shared/utils/constants.ts'

import {
  defaultUser,
  mockUserDetailsApis,
} from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'

import { defaultTicket, mockTicketDetailViewGql } from './mocks/detail-view.ts'

const visitTicketUser = async (user: ConfidentTake<UserQuery, 'user'>) => {
  mockTicketDetailViewGql()

  const { mockUser, mockUserSubscription, mockAttributes } = mockUserDetailsApis(user, {
    skipMockOnlineNotificationSeen: true,
  })

  const view = await visitView('/tickets/1/information/customer')

  await waitUntilApisResolved(mockUser, mockAttributes)

  // since we have a form with similar labels outside of the view, we need to narrow down the scope
  const helpers = within(view.container as HTMLElement)

  return {
    view: helpers,
    mockUser,
    mockAttributes,
    mockUserSubscription,
  }
}

describe('visiting ticket user page', () => {
  test('view static content', async () => {
    mockPermissions(['ticket.agent'])
    const user = defaultUser()
    const { view } = await visitTicketUser(user)

    expect(view.queryByRole('region', { name: 'First name' })).not.toBeInTheDocument()
    expect(view.queryByRole('region', { name: 'Last  name' })).not.toBeInTheDocument()

    const ticketOpenLink = view.getByRole('link', { name: 'open 4' })
    const ticketClosedLink = view.getByRole('link', { name: 'closed 2' })

    expect(ticketOpenLink).toHaveAttribute(
      'href',
      expect.stringContaining(`customer.id: ${user.internalId}`),
    )
    expect(ticketClosedLink).toHaveAttribute(
      'href',
      expect.stringContaining(`customer.id: ${user.internalId}`),
    )

    expect(view.getByText('Secondary organizations')).toBeInTheDocument()
    expect(view.getByText('Dammaz')).toBeInTheDocument()
  })

  test('view fully configured user', async () => {
    mockPermissions(['ticket.agent'])
    const userDefault = defaultUser()
    const [department, address] = userDefault.objectAttributeValues!
    const user = {
      ...userDefault,
      image: 'data:image/png;base64,1234567890',
      email: 'some-email@mail.com',
      web: 'https://some-web.com',
      vip: true,
      outOfOffice: false,
      outOfOfficeStartAt: null,
      outOfOfficeEndAt: null,
      phone: '80542243532',
      mobile: '2432332143',
      fax: 'fax.fax',
      note: 'This user is cool',
      objectAttributeValues: [
        {
          ...department,
          value: 'Department of Health and Safety',
        },
        {
          ...address,
          value: 'Berlin',
        },
      ],
    }
    const { mockUser, mockAttributes } = mockUserDetailsApis(user)

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    const getRegion = (name: string) => view.getByRole('region', { name })

    expect(view.getByIconName('crown'), 'vip has crown').toBeInTheDocument()

    expect(view.queryByRole('region', { name: 'First name' })).not.toBeInTheDocument()
    expect(view.queryByRole('region', { name: 'Last  name' })).not.toBeInTheDocument()
    expect(getRegion('Email')).toHaveTextContent('some-email@mail.com')
    expect(getRegion('Web')).toHaveTextContent('https://some-web.com')
    expect(getRegion('Phone')).toHaveTextContent('80542243532')
    expect(getRegion('Mobile')).toHaveTextContent('2432332143')
    expect(getRegion('Fax')).toHaveTextContent('fax.fax')
    expect(getRegion('Note')).toHaveTextContent('This user is cool')
    expect(getRegion('Department')).toHaveTextContent('Department of Health and Safety')
    expect(getRegion('Address')).toHaveTextContent('Berlin')
  })

  it('shows the system customer as no customer without loading it', async () => {
    mockPermissions(['ticket.agent'])

    const ticket = defaultTicket()

    ticket.ticket.customer = {
      ...ticket.ticket.customer,
      id: SYSTEM_USER_ID,
      internalId: SYSTEM_USER_INTERNAL_ID,
      firstname: '-',
      lastname: '',
      fullname: '-',
      active: false,
    }

    mockTicketDetailViewGql({ ticket })

    const { mockUser } = mockUserDetailsApis(undefined, {
      skipMockOnlineNotificationSeen: true,
    })

    const view = await visitView('/tickets/1/information/customer')

    expect(await view.findByText('No customer assigned yet.')).toBeInTheDocument()
    expect(view.getByRole('tab', { name: 'Customer' })).toBeInTheDocument()
    expect(mockUser.calls.resolve).toBe(0)
    expect(view.queryByRole('button', { name: 'Edit Customer' })).not.toBeInTheDocument()
  })

  it('cannot edit user without permission', async () => {
    mockPermissions([])
    const user = defaultUser()
    user.policy.update = false
    const { view } = await visitTicketUser(user)

    expect(view.queryByRole('button', { name: 'Edit Customer' })).not.toBeInTheDocument()
  })
})
