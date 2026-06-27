// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import FormUpdaterUser from '#tests/graphql/factories/types/FormUpdaterUser.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitUntil } from '#tests/support/vitest-wrapper.ts'

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { waitForUserAddMutationCalls } from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import type { FormUpdaterQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { handleMockFormUpdaterQuery, visitCreateView } from '../support/ticket-create-helpers.ts'

describe('ticket create view - user create action', () => {
  beforeEach(() => {
    // Main form
    handleMockFormUpdaterQuery()
  })

  it('does not allow agent to toggle customer role when creating user', async () => {
    mockPermissions(['ticket.agent'])

    const view = await visitCreateView()

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        attributes: [],
        screens: [
          {
            name: 'create',
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

    await view.events.click(await view.findByLabelText('Create new customer'))

    const flyout = await view.findByRole('complementary', { name: 'Create new customer' })

    const emailField = await within(flyout).findByLabelText('Email')

    await view.events.type(emailField, 'foo@customer.com')

    // Wait for a form updater call carrying the typed email value.
    // This ensures FormKit has committed the input (20 ms async delay) before
    // we submit — the initial form updater fires with data:{} and must not be
    // mistaken for the field-change-triggered call.
    await waitUntil(() => {
      const calls = getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument)
      return calls.some((call) => call.variables.data?.email === 'foo@customer.com')
    })

    const customerSwitch = within(flyout).queryByRole('switch', {
      name: 'CustomerPeople who create Tickets ask for help.',
    })

    expect(customerSwitch).not.toBeInTheDocument()

    await view.events.click(within(flyout).getByRole('button', { name: 'Create' }))

    const calls = await waitForUserAddMutationCalls()

    // Agent should create users without explicitly setting roleIds (defaults will apply on backend)
    expect(calls[0].variables.input).toMatchObject({
      email: 'foo@customer.com',
    })

    expect(calls[0].variables.input.roleIds).toBeUndefined()
  })

  it('allows admin to create user and toggle customer role', async () => {
    mockPermissions(['admin.user', 'ticket.agent'])

    const view = await visitCreateView()

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        attributes: [],
        screens: [
          {
            name: 'create',
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

    await view.events.click(await view.findByLabelText('Create new customer'))

    const flyout = await view.findByRole('complementary', { name: 'Create new customer' })

    const emailField = await within(flyout).findByLabelText('Email')

    await view.events.type(emailField, 'foo@customer.com')

    await waitUntil(() => {
      const calls = getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument)
      return calls.some((call) => call.variables.data?.email === 'foo@customer.com')
    })

    const afterEmailFormUpdaterCallCount =
      getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument).length

    const customerSwitch = within(flyout).getByRole('switch', {
      name: 'CustomerPeople who create Tickets ask for help.',
    })

    expect(customerSwitch).toBeEnabled()

    await view.events.click(customerSwitch)

    await waitUntil(() => {
      return (
        getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument).length >
        afterEmailFormUpdaterCallCount
      )
    })

    await view.events.click(within(flyout).getByRole('button', { name: 'Create' }))

    const calls = await waitForUserAddMutationCalls()

    expect(calls[0].variables.input).toMatchObject({
      email: 'foo@customer.com',
      roleIds: [convertToGraphQLId('Role', 3)],
    })
  })
})
