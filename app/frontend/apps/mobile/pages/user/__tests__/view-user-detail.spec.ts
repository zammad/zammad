// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  defaultUser,
  mockUserDetailsApis,
} from '@mobile/entities/user/__tests__/mocks/user-mocks'
import { visitView } from '@tests/support/components/visitView'
import { waitUntilApisResolved } from '@tests/support/utils'

describe('visiting user page', () => {
  test('view static content', async () => {
    const { mockUser, mockAttributes, user } = mockUserDetailsApis()

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    const organization = user.organization!

    expect(
      view.getByRole('img', { name: 'Avatar (John Doe)' }),
    ).toBeInTheDocument()

    const organizationLink = view.getByRole('link', {
      name: organization.name!,
    })

    expect(organizationLink).toBeInTheDocument()
    expect(organizationLink).toHaveAttribute(
      'href',
      `/organizations/${organization.internalId}`,
    )

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

  test('can toggle tickets count view', async () => {
    const { mockUser, mockAttributes, user } = mockUserDetailsApis()

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    const ticketOpenLink = view.getByRole('link', { name: 'open 4' })
    const ticketClosedLink = view.getByRole('link', { name: 'closed 2' })

    expect(ticketOpenLink).toBeInTheDocument()
    expect(ticketClosedLink).toBeInTheDocument()

    await view.events.click(
      view.getByRole('tab', { name: 'Organization tickets' }),
    )

    const organization = user.organization!

    const ticketOrganizationOpenLink = view.getByRole('link', {
      name: 'open 3',
    })
    const ticketOrganizationClosedLink = view.getByRole('link', {
      name: 'closed 1',
    })

    expect(ticketOrganizationOpenLink).toHaveAttribute(
      'href',
      expect.stringContaining(`organization.id: ${organization.internalId}`),
    )
    expect(ticketOrganizationClosedLink).toHaveAttribute(
      'href',
      expect.stringContaining(`organization.id: ${organization.internalId}`),
    )
    expect(
      view.getByRole('link', {
        name: 'Create new ticket for this organization',
      }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('tab', { name: 'Their tickets' }))

    expect(view.getByRole('link', { name: 'open 4' })).toBeInTheDocument()
    expect(view.getByRole('link', { name: 'closed 2' })).toBeInTheDocument()
    expect(
      view.getByRole('link', { name: 'Create new ticket for this user' }),
    ).toBeInTheDocument()
  })

  test('view user without organization', async () => {
    const user = defaultUser()
    user.organization = null

    const { mockUser, mockAttributes } = mockUserDetailsApis(user)

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    expect(view.queryByTestId('organization-link')).not.toBeInTheDocument()
    expect(
      view.queryByRole('button', { name: 'Their tickets' }),
    ).not.toBeInTheDocument()
    expect(
      view.queryByRole('button', { name: 'Organization tickets' }),
    ).not.toBeInTheDocument()
  })

  test('view fully configured user', async () => {
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
})
