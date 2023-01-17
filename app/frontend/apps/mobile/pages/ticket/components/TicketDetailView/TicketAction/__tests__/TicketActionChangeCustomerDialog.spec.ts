// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { mockPermissions } from '@tests/support/mock-permissions'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { MutationHandler } from '@shared/server/apollo/handler'
import { AutocompleteSearchUserDocument } from '@shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api'
import { mockTicketObjectAttributesGql } from '@mobile/entities/ticket/__tests__/mocks/ticket-mocks'
import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import type { AutocompleteSearchUserQuery } from '@shared/graphql/types'
import TicketActionChangeCustomerDialog from '../TicketActionChangeCustomerDialog.vue'

beforeAll(async () => {
  await import(
    '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInputDialog.vue'
  )
})

const { ticket: currentTicket } = defaultTicket()

const mockUpdateMutationHandler = () => {
  const sendMock = vi.fn()
  MutationHandler.prototype.send = sendMock

  return {
    sendMock,
  }
}

const defaultAutoCompleteSearchUserResult = (
  hasSecondaryOrganizations = false,
): AutocompleteSearchUserQuery => ({
  autocompleteSearchUser: [
    nullableMock({
      value: '2',
      label: 'Nicole Braun',
      labelPlaceholder: null,
      heading: 'Zammad Foundation',
      headingPlaceholder: null,
      disabled: null,
      icon: null,
      user: {
        id: 'gid://zammad/User/2',
        internalId: 2,
        firstname: 'Nicole',
        lastname: 'Braun',
        fullname: 'Nicole Braun',
        image: null,
        objectAttributeValues: [],
        organization: {
          id: 'gid://zammad/Organization/1',
          internalId: 1,
          name: 'Zammad Foundation',
          active: true,
          objectAttributeValues: [],
          __typename: 'Organization',
        },
        hasSecondaryOrganizations,
        __typename: 'User',
      },
      __typename: 'AutocompleteSearchUserEntry',
    }),
  ],
})

const mockCustomerQueryResult = (
  autoCompleteSearchUserResult?: AutocompleteSearchUserQuery[],
) => {
  return mockGraphQLApi(AutocompleteSearchUserDocument).willResolve(
    autoCompleteSearchUserResult || defaultAutoCompleteSearchUserResult(),
  )
}

describe('TicketAction - change customer dialog', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockTicketObjectAttributesGql()
  })

  test('show customer action and cancel with confirmation', async () => {
    const mockCustomer = mockCustomerQueryResult()

    const view = renderComponent(TicketActionChangeCustomerDialog, {
      props: {
        name: 'ticket-change-customer',
        ticket: currentTicket,
      },
      store: true,
      dialog: true,
      form: true,
      router: true,
      confirmation: true,
    })

    await waitUntil(() => view.queryByLabelText('Customer'))

    await view.events.click(view.getByLabelText('Customer'))
    await expect(
      view.findByRole('dialog', { name: 'Customer' }),
    ).resolves.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'nicole')

    await waitUntil(() => mockCustomer.calls.resolve)

    await view.events.click(view.getByText('Nicole Braun'))
    await view.events.click(view.getByRole('button', { name: 'Cancel' }))

    await expect(
      view.findByRole('alert', { name: 'Confirm dialog' }),
    ).resolves.toBeInTheDocument()
  })

  test('can change customer', async () => {
    const { sendMock } = mockUpdateMutationHandler()
    const mockCustomer = mockCustomerQueryResult()

    const view = renderComponent(TicketActionChangeCustomerDialog, {
      props: {
        name: 'ticket-change-customer',
        ticket: currentTicket,
      },
      store: true,
      dialog: true,
      form: true,
      router: true,
      confirmation: true,
    })

    await waitUntil(() => view.queryByLabelText('Customer'))

    await view.events.click(view.getByLabelText('Customer'))
    await expect(
      view.findByRole('dialog', { name: 'Customer' }),
    ).resolves.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'nicole')

    await waitUntil(() => mockCustomer.calls.resolve)

    await view.events.click(view.getByText('Nicole Braun'))
    await view.events.click(view.getByRole('button', { name: 'Save' }))

    expect(sendMock).toHaveBeenCalledOnce()
    expect(sendMock).toHaveBeenCalledWith({
      ticketId: currentTicket.id,
      input: {
        customerId: 'gid://zammad/User/2',
      },
    })
  })

  test('show organization field for customers with multiple organization (and also hide again)', async () => {
    const mockCustomer = mockCustomerQueryResult([
      defaultAutoCompleteSearchUserResult(true),
      {
        autocompleteSearchUser: [
          nullableMock({
            value: '200',
            label: 'John Doe',
            labelPlaceholder: null,
            heading: 'Example AG',
            headingPlaceholder: null,
            disabled: null,
            icon: null,
            user: {
              __typename: 'User',
              id: 'gid://zammad/User/200',
              internalId: 200,
              firstname: 'John',
              lastname: 'Doe',
              fullname: 'John Doe',
              image: null,
              objectAttributeValues: [],
              organization: {
                id: 'gid://zammad/Organization/10',
                internalId: 1,
                name: 'Example AG',
                active: true,
                objectAttributeValues: [],
                __typename: 'Organization',
              },
              hasSecondaryOrganizations: false,
            },
            __typename: 'AutocompleteSearchUserEntry',
          }),
        ],
      },
    ])

    const view = renderComponent(TicketActionChangeCustomerDialog, {
      props: {
        name: 'ticket-change-customer',
        ticket: currentTicket,
      },
      store: true,
      dialog: true,
      form: true,
      router: true,
      confirmation: true,
    })

    await waitUntil(() => view.queryByLabelText('Customer'))

    await view.events.click(view.getByLabelText('Customer'))
    await expect(
      view.findByRole('dialog', { name: 'Customer' }),
    ).resolves.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'nicole')
    await waitUntil(() => mockCustomer.calls.resolve === 1)
    await view.events.click(view.getByText('Nicole Braun'))

    await waitFor(() => {
      expect(view.queryByLabelText('Organization')).toBeInTheDocument()
    })

    await view.events.click(view.getByLabelText('Customer'))
    await view.events.type(view.getByRole('searchbox'), 'john')
    await waitUntil(() => mockCustomer.calls.resolve === 2)
    await view.events.click(view.getByText('John Doe'))

    expect(view.queryByLabelText('Organization')).not.toBeInTheDocument()
  })
})
