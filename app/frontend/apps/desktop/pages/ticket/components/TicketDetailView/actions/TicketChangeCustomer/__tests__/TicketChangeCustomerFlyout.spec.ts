// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchGenericQuery,
  waitForAutocompleteSearchGenericQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.mocks.ts'
import { waitForTicketCustomerUpdateMutationCalls } from '#shared/entities/ticket/graphql/mutations/customerUpdate.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { testOptions } from '#desktop/components/Form/fields/FieldCustomer/__tests__/support/testOptions.ts'

import TicketChangeCustomerFlyout from '../TicketChangeCustomerFlyout.vue'

describe('TicketChangeCustomerFlyout', () => {
  it('updates customer information.', async () => {
    const wrapper = renderComponent(TicketChangeCustomerFlyout, {
      props: {
        ticket: createDummyTicket(),
        name: 'create-customer',
      },
      flyout: true,
      store: true,
      form: true,
    })

    expect(
      wrapper.getByRole('heading', { name: 'Change Customer', level: 2 }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('person')).toBeInTheDocument()

    expect(await wrapper.findByLabelText('Customer')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Nicole Braun')).toBeInTheDocument()

    mockAutocompleteSearchGenericQuery({
      autocompleteSearchGeneric: testOptions,
    })

    await wrapper.events.click(wrapper.getByLabelText('Customer'))

    expect(wrapper.getByRole('menu')).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'zammad')

    await waitForAutocompleteSearchGenericQueryCalls()

    await wrapper.events.click(wrapper.getAllByRole('option')[0])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

    const calls = await waitForTicketCustomerUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        customerId: convertToGraphQLId('User', 2),
      },
      ticketId: convertToGraphQLId('Ticket', 1),
    })
  })
})
