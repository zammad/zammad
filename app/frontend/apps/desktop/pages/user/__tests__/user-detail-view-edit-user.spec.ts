// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import FormUpdaterUser from '#tests/graphql/factories/types/FormUpdaterUser.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { waitForUserUpdateMutationCalls } from '#shared/entities/user/graphql/mutations/update.mocks.ts'
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

describe('User Detail View - Edit User', () => {
  beforeEach(() => {
    mockUserQuery({ user })
  })

  it('updates user details', async () => {
    mockPermissions(['ticket.agent'])

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        attributes: [],
        screens: [
          {
            name: 'edit',
            attributes: [
              'firstname',
              'lastname',
              'email',
              'web',
              'phone',
              'mobile',
              'fax',
              'organization_id',
              'organization_ids',
              'address',
              'password',
              'vip',
              'note',
              'role_ids',
              'group_ids',
            ],
          },
        ],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: FormUpdaterUser(),
    })

    const view = await visitView('/users/2')

    await view.events.click(view.getByRole('button', { name: 'Action menu button' }))

    const popover = await view.findByRole('region', { name: 'Action menu button' })

    await view.events.click(within(popover).getByRole('button', { name: 'Edit' }))

    const flyout = await view.findByRole('complementary', { name: 'Edit user' })

    const firstname = await within(flyout).findByLabelText('First name')

    await view.events.clear(firstname)
    await view.events.type(firstname, 'Thomas')

    // FIX: Clear the invalid 'web' field which gets auto-mocked with a wrong value
    const webField = await within(flyout).findByLabelText('Web')
    await view.events.clear(webField)

    const updateButton = within(flyout).getByRole('button', { name: 'Update' })

    await view.events.click(updateButton)

    const calls = await waitForUserUpdateMutationCalls()

    expect(calls.at(-1)?.variables.input).toMatchObject({
      firstname: 'Thomas',
    })
  })

  it('does not allow agent to toggle customer role', async () => {
    mockPermissions(['ticket.agent'])

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        attributes: [
          {
            name: 'role_ids',
            display: 'Roles',
            dataType: 'user_permission',
            dataOption: {
              relation: 'Role',
              null: false,
              item_class: 'checkbox',
              permission: ['admin.user'],
              belongs_to: 'role ids',
            },
            isInternal: true,
            screens: {
              signup: {},
              invite_agent: {
                null: false,
                default: [2],
              },
              invite_customer: {},
              edit: {
                null: true,
              },
              create: {
                null: true,
              },
              view: {
                shown: false,
              },
            },
            __typename: 'ObjectManagerFrontendAttribute',
          },
        ],
        screens: [
          {
            name: 'edit',
            attributes: [
              'firstname',
              'lastname',
              'email',
              'web',
              'phone',
              'mobile',
              'fax',
              'organization_id',
              'organization_ids',
              'address',
              'password',
              'vip',
              'note',
              'role_ids',
              'group_ids',
            ],
          },
        ],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        ...FormUpdaterUser(),
        fields: {
          ...FormUpdaterUser().fields,
          role_ids: {
            ...FormUpdaterUser().fields!.role_ids,
            show: false,
            hidden: true,
          },
        },
      },
    })

    const view = await visitView('/users/2')

    await view.events.click(view.getByRole('button', { name: 'Action menu button' }))

    const popover = await view.findByRole('region', { name: 'Action menu button' })

    await view.events.click(within(popover).getByRole('button', { name: 'Edit' }))

    const flyout = await view.findByRole('complementary', { name: 'Edit user' })

    const customerSwitch = within(flyout).queryByRole('switch', {
      name: 'CustomerPeople who create Tickets ask for help.',
    })

    expect(customerSwitch).not.toBeInTheDocument()
  })
})
