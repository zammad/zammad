// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { waitUntil, waitUntilApisResolved } from '#tests/support/utils.ts'

import { UserDocument } from '#shared/entities/user/graphql/queries/user.api.ts'

import {
  defaultUser,
  mockUserDetailsApis,
} from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'

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
      `/mobile/organizations/${organization.internalId}`,
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

  it('can edit user with required update policy', async () => {
    const { mockUser, mockAttributes, user } = mockUserDetailsApis()

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    expect(view.getByRole('button', { name: 'Edit' })).toBeInTheDocument()
  })

  it('cannot edit user without required update policy', async () => {
    const user = defaultUser()
    user.policy.update = false

    const { mockUser, mockAttributes } = mockUserDetailsApis(user)

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    expect(view.queryByRole('button', { name: 'Edit' })).not.toBeInTheDocument()
  })

  it('redirects to error page if user is not found', async () => {
    setupView('agent')

    const mockApi = mockGraphQLApi(UserDocument).willFailWithNotFoundError()

    const view = await visitView('/users/123')

    await waitUntil(() => mockApi.calls.error)

    await expect(view.findByText('Not found')).resolves.toBeInTheDocument()
  })

  it('redirects to error page if access to organization is forbidden', async () => {
    setupView('agent')

    const mockApi = mockGraphQLApi(UserDocument).willFailWithForbiddenError()
    const view = await visitView('/users/123')

    await waitUntil(() => mockApi.calls.error)

    await expect(view.findByText('Forbidden')).resolves.toBeInTheDocument()
  })
})

test('correctly redirects from hash-based routes', async () => {
  setupView('agent')
  await visitView('/#user/profile/1')
  const router = getTestRouter()
  const route = router.currentRoute.value
  expect(route.name).toBe('UserDetailView')
  expect(route.params).toEqual({ internalId: '1' })
})
