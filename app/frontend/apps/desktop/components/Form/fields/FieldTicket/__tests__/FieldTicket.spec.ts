// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { nullableMock } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchTicketQuery,
  waitForAutocompleteSearchTicketQueryCalls,
} from '#shared/entities/ticket/graphql/queries/autocompleteSearchTicket.mocks.ts'
import {
  EnumTicketStateColorCode,
  type AutocompleteSearchTicketQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

const testOptions: AutocompleteSearchTicketQuery['autocompleteSearchTicket'][0][] =
  [
    {
      __typename: 'AutocompleteSearchTicketEntry',
      value: convertToGraphQLId('Ticket', 1),
      label: 'Sample title 1',
      labelPlaceholder: [],
      heading: 'Ticket#123456 - Max Mustermann',
      headingPlaceholder: [],
      disabled: false,
      icon: null,
      ticket: nullableMock({
        id: convertToGraphQLId('Ticket', 1),
        internalId: 1,
        number: '123456',
        state: nullableMock({
          id: convertToGraphQLId('TicketState', 1),
          name: 'open',
        }),
        stateColorCode: EnumTicketStateColorCode.Open,
      }),
    },
    {
      __typename: 'AutocompleteSearchTicketEntry',
      value: convertToGraphQLId('Ticket', 2),
      label: 'Sample title 2',
      labelPlaceholder: [],
      heading: 'Ticket#55555 - Max Mustermann',
      headingPlaceholder: [],
      disabled: false,
      icon: null,
      ticket: nullableMock({
        id: convertToGraphQLId('Ticket', 2),
        internalId: 1,
        number: '55555',
        state: nullableMock({
          id: convertToGraphQLId('TicketState', 1),
          name: 'open',
        }),
        stateColorCode: EnumTicketStateColorCode.Open,
      }),
    },
    {
      __typename: 'AutocompleteSearchTicketEntry',
      value: convertToGraphQLId('Ticket', 3),
      label: 'Sample title 3',
      labelPlaceholder: [],
      heading: 'Ticket#99999 - Max Mustermann',
      headingPlaceholder: [],
      disabled: false,
      icon: null,
      ticket: nullableMock({
        id: convertToGraphQLId('Ticket', 3),
        internalId: 1,
        number: '99999',
        state: nullableMock({
          id: convertToGraphQLId('TicketState', 1),
          name: 'open',
        }),
        stateColorCode: EnumTicketStateColorCode.Open,
      }),
    },
  ]

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  store: true,
}

const testProps = {
  type: 'ticket',
  label: 'Select…',
}

describe('Form - Field - Ticket - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchTicketQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    expect(
      getByIconName(selectOptions[0], 'check-circle-no'),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, testOptions[1].label)

    await waitForAutocompleteSearchTicketQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)

    await wrapper.events.clear(filterElement)

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [testOptions[2]],
    })

    await wrapper.events.type(filterElement, testOptions[2].label)

    await waitForAutocompleteSearchTicketQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)
  })

  it('replaces local options with selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchTicketQueryCalls()

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('check2')).toBeInTheDocument()
  })

  it('supports filtering out specific user', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        exceptTicketInternalId: 999,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [...testOptions.slice(0, 1)],
    })

    await wrapper.events.type(filterElement, '*')

    const calls = await waitForAutocompleteSearchTicketQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        exceptTicketInternalId: 999,
      }),
    })
  })

  it('supports removing ticket hook from filter', async () => {
    mockApplicationConfig({
      ticket_hook: 'Ticket#',
    })

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchTicketQuery({
      autocompleteSearchTicket: [...testOptions.slice(0, 1)],
    })

    await wrapper.events.type(filterElement, 'Ticket#123456')

    const calls = await waitForAutocompleteSearchTicketQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        query: '123456',
      }),
    })
  })
})
