// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  defaultUser,
  mockUserDetailsApis,
} from '@mobile/entities/user/__tests__/mocks/user-mocks'
import type { UserQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { within } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
import { mockPermissions } from '@tests/support/mock-permissions'
import { waitUntilApisResolved } from '@tests/support/utils'
import { mockTicketDetailViewGql } from './mocks/detail-view'

const visitTicketUser = async (user: ConfidentTake<UserQuery, 'user'>) => {
  mockTicketDetailViewGql()

  const { mockUser, mockUserSubscription, mockAttributes } =
    mockUserDetailsApis(user)

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

    expect(
      view.queryByRole('region', { name: 'First name' }),
    ).not.toBeInTheDocument()
    expect(
      view.queryByRole('region', { name: 'Last  name' }),
    ).not.toBeInTheDocument()

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

    expect(
      view.getByIconName('mobile-crown'),
      'vip has crown',
    ).toBeInTheDocument()

    expect(
      view.queryByRole('region', { name: 'First name' }),
    ).not.toBeInTheDocument()
    expect(
      view.queryByRole('region', { name: 'Last  name' }),
    ).not.toBeInTheDocument()
    expect(getRegion('Email')).toHaveTextContent('some-email@mail.com')
    expect(getRegion('Web')).toHaveTextContent('https://some-web.com')
    expect(getRegion('Phone')).toHaveTextContent('80542243532')
    expect(getRegion('Mobile')).toHaveTextContent('2432332143')
    expect(getRegion('Fax')).toHaveTextContent('fax.fax')
    expect(getRegion('Note')).toHaveTextContent('This user is cool')
    expect(getRegion('Department')).toHaveTextContent(
      'Department of Health and Safety',
    )
    expect(getRegion('Address')).toHaveTextContent('Berlin')
  })

  it('cannot edit user without permission', async () => {
    mockPermissions([])
    const user = defaultUser()
    const { view } = await visitTicketUser(user)

    expect(
      view.queryByRole('button', { name: 'Edit Customer' }),
    ).not.toBeInTheDocument()
  })
})
