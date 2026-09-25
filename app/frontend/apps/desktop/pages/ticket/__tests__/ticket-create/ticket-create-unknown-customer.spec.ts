// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockAutocompleteSearchGenericQuery,
  waitForAutocompleteSearchGenericQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.mocks.ts'
import { UserDocument } from '#shared/entities/user/graphql/queries/user.api.ts'

import { handleMockFormUpdaterQuery, visitCreateView } from '../support/ticket-create-helpers.ts'

describe('ticket create view - unknown customer typed into the customer field', () => {
  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })
    mockPermissions(['ticket.agent'])
  })

  // A number made of digits only looks like a user ID, but is no more a known customer
  //   than an email address is, so the customer sidebar must stay away for both.
  it.each([
    ['phone number', '4930777000999', 'add new phone number'],
    ['international phone number', '+4930777000999', 'add new phone number'],
    ['email address', 'jane.doe@example.com', 'add new email address'],
  ])('takes a typed-in %s as the customer without looking up a user', async (_, value, action) => {
    handleMockFormUpdaterQuery()
    mockAutocompleteSearchGenericQuery({ autocompleteSearchGeneric: [] })

    const view = await visitCreateView()

    await view.events.type(await view.findByLabelText('Customer'), value)
    await waitForAutocompleteSearchGenericQueryCalls()

    await view.events.click(await view.findByRole('button', { name: action }))

    expect(view.getByLabelText('Customer')).toHaveTextContent(value)
    expect(view.queryByRole('button', { name: 'Customer' })).not.toBeInTheDocument()
    expect(getGraphQLMockCalls(UserDocument)).toHaveLength(0)
  })
})
