// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import FormUpdaterUser from '#tests/graphql/factories/types/FormUpdaterUser.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { waitForUserAddMutationCalls } from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import type { FormUpdaterQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { initializeFormFields } from '#desktop/form/index.ts'

import { handleMockFormUpdaterQuery, visitCreateView } from '../support/ticket-create-helpers.ts'

describe('ticket create view - user create action', () => {
  beforeAll(() => {
    // Initialize the desktop form field classes like the real app does. The
    // `formkit-link` marker class on the "Create new customer" link makes
    // `useFormBlock` ignore clicks on it - without the class, the click also
    // opens the customer_id autocomplete dropdown (500 ms debounced), which
    // then steals the focus while we are typing into the flyout form.
    initializeFormFields()
  })

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

    // The flyout form autofocuses its first input ("First name") asynchronously
    // after it has settled. If we start typing before that, the autofocus steals
    // the focus mid-typing and the remaining keystrokes are lost (userEvent types
    // into the active element). Waiting for the autofocus also guarantees the
    // fields are settled and visible.
    await waitFor(() => expect(within(flyout).getByLabelText('First name')).toHaveFocus())

    await view.events.type(emailField, 'foo@customer.com')

    // Wait for a form updater call carrying the typed email value.
    // This ensures FormKit has committed the input (20 ms async delay) before
    // we submit - the initial form updater fires with data:{} and must not be
    // mistaken for the field-change-triggered call.
    // Uses sync getGraphQLMockCalls to avoid blocking waitFor with a long-lived vi.waitUntil.
    await waitFor(() => {
      const calls = getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument)
      expect(calls.some((call) => call.variables.data?.email === 'foo@customer.com')).toBe(true)
    })

    // The mock records the call before delivering the response to Apollo. Flush all pending
    // microtasks so Apollo processes the response and Form.vue's nextTick removes
    // formUpdaterProcessing — otherwise clicking Create silences the submitted message.
    // flushPromises uses setImmediate (one tick), but Apollo's result chain can span multiple
    // ticks, so flush twice.
    await flushPromises()
    await flushPromises()

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

    // The flyout form autofocuses its first input ("First name") asynchronously
    // after it has settled. If we start typing before that, the autofocus steals
    // the focus mid-typing and the remaining keystrokes are lost (userEvent types
    // into the active element). Waiting for the autofocus also guarantees the
    // fields are settled and visible.
    await waitFor(() => expect(within(flyout).getByLabelText('First name')).toHaveFocus())

    await view.events.type(emailField, 'foo@customer.com')

    let afterEmailFormUpdaterCallCount: number

    // Uses sync getGraphQLMockCalls to avoid blocking waitFor with a long-lived vi.waitUntil.
    await waitFor(() => {
      const calls = getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument)
      expect(calls.some((call) => call.variables.data?.email === 'foo@customer.com')).toBe(true)
      afterEmailFormUpdaterCallCount = calls.length
    })

    // Flush all pending microtasks so Apollo delivers the response and Form.vue's nextTick
    // removes formUpdaterProcessing before we interact with the form further.
    // flushPromises uses setImmediate (one tick); flush twice to cover the full chain.
    await flushPromises()
    await flushPromises()

    const customerSwitch = within(flyout).getByRole('switch', {
      name: 'CustomerPeople who create Tickets ask for help.',
    })

    expect(customerSwitch).toBeEnabled()

    await view.events.click(customerSwitch)

    await waitFor(() => {
      expect(getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument).length).toBeGreaterThan(
        afterEmailFormUpdaterCallCount!,
      )
    })

    // Same double flush needed before clicking Create to avoid formUpdaterProcessing blocking submission.
    await flushPromises()
    await flushPromises()

    await view.events.click(within(flyout).getByRole('button', { name: 'Create' }))

    const calls = await waitForUserAddMutationCalls()

    expect(calls[0].variables.input).toMatchObject({
      email: 'foo@customer.com',
      roleIds: [convertToGraphQLId('Role', 3)],
    })
  })
})
