// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { escapeRegExp } from 'lodash-es'
import gql from 'graphql-tag'
import { getByTestId, waitFor } from '@testing-library/vue'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import testOptions from '@shared/components/Form/fields/FieldCustomer/__tests__/test-options.json'
import type { AvatarUser } from '@shared/components/CommonUserAvatar/types'

const AutocompleteSearchCustomerDocument = gql`
  query autocompleteSearchCustomer($query: String!, $limit: Int) {
    autocompleteSearchCustomer(query: $query, limit: $limit) {
      value
      label
      labelPlaceholder
      heading
      headingPlaceholder
      disabled
      user
    }
  }
`

type AutocompleteSearchCustomerQuery = {
  __typename?: 'Queries'
  autocompleteSearchCustomer: Array<{
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    heading?: string | null
    headingPlaceholder?: Array<string> | null
    disabled?: boolean | null
    user?: AvatarUser
  }>
}

const mockQueryResult = (
  query: string,
  limit: number,
): AutocompleteSearchCustomerQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
    __typename: 'AutocompleteEntry',
  }))

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter(
    (option) =>
      filterRegex.test(deaccent(option.label)) ||
      filterRegex.test(deaccent(option.heading)),
  ) as unknown as {
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    disabled?: boolean | null
    user?: AvatarUser
  }[]

  return {
    autocompleteSearchCustomer: filteredOptions.slice(0, limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchCustomerDocument,
    (variables) => {
      return Promise.resolve({
        data: mockQueryResult(variables.query, variables.limit),
      })
    },
  )

  provideApolloClient(mockApolloClient)
}

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'customer',
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../../FieldAutoComplete/FieldAutoCompleteInputDialog.vue')
})

// We include only some query-related test cases, as the actual autocomplete component has its own unit test.
describe('Form - Field - Customer - Query', () => {
  mockClient()

  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    // Resolve `defineAsyncComponent()` calls first.
    await vi.dynamicImportSettled()

    await wrapper.events.click(wrapper.getByRole('list'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'adam')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].heading)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[0].user.image})`,
    })

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodríguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].heading)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[1].user.image})`,
    })

    await wrapper.events.clear(filterElement)

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodríguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].heading)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[1].user.image})`,
    })
  })

  it('replaces local options with selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    // Resolve `defineAsyncComponent()` calls first.
    await vi.dynamicImportSettled()

    await wrapper.events.click(wrapper.getByRole('list'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'adam')

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getByIconName('check')).toBeInTheDocument()
  })
})
