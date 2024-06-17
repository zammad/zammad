// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { within, waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchRecipientQuery,
  waitForAutocompleteSearchRecipientQueryCalls,
} from '#shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.mocks.ts'
import type { AutocompleteSearchRecipientEntry } from '#shared/graphql/types.ts'

import type { SetRequired } from 'type-fest'

const testOptions: SetRequired<
  Partial<AutocompleteSearchRecipientEntry>,
  'label'
>[] = [
  {
    value: 'baz@bar.tld',
    label: 'Baz',
  },
  {
    value: 'qux@bar.tld',
    label: 'Qux',
  },
  {
    value: 'corge@bar.tld',
    label: 'Corge',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  store: true,
}

const testProps = {
  type: 'recipient',
  label: 'Recipient',
  multiple: true,
}

describe('Form - Field - Recipient - Features', () => {
  it('supports adding and removing of new unknown values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        contact: 'email',
        debounceInterval: 10,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Recipient'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    mockAutocompleteSearchRecipientQuery({
      autocompleteSearchRecipient: [],
    })

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).toBeInTheDocument()

    await wrapper.events.type(filterElement, 'foo@bar.tld')

    await waitForAutocompleteSearchRecipientQueryCalls()

    await wrapper.events.click(
      await wrapper.findByText('add new email address'),
    )

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual(['foo@bar.tld'])

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('foo@bar.tld')

    const listitem = within(wrapper.getByRole('listitem'))

    await wrapper.events.click(
      listitem.getByRole('button', { name: 'Unselect Option' }),
    )

    expect(emittedInput[1][0]).toEqual([])
  })

  it('supports search and input of contact phone options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        contact: 'phone',
        debounceInterval: 10,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Recipient'))

    expect(
      wrapper.queryByText('Start typing to search or enter a phone number…'),
    ).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')
    await wrapper.events.type(filterElement, '+499876543210')

    expect(await wrapper.findByText('add new phone number')).toBeInTheDocument()
  })
})

describe('Form - Field - Recipient - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        contact: 'email',
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Recipient'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    mockAutocompleteSearchRecipientQuery({
      autocompleteSearchRecipient: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchRecipientQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchRecipientQuery({
      autocompleteSearchRecipient: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, testOptions[1].label)

    await waitForAutocompleteSearchRecipientQueryCalls()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
  })
})
