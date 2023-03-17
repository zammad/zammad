// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { escapeRegExp } from 'lodash-es'
import { waitFor } from '@testing-library/vue'
import { FormKit } from '@formkit/vue'
import { getNode } from '@formkit/core'
import { renderComponent } from '@tests/support/components'
import { queryByIconName } from '@tests/support/components/iconQueries'
import testOptions from '@shared/components/Form/fields/FieldOrganization/__tests__/test-options.json'
import type {
  AutocompleteSearchOrganizationEntry,
  AutocompleteSearchOrganizationQuery,
} from '@shared/graphql/types'
import type { MockGraphQLInstance } from '@tests/support/mock-graphql-api'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { nullableMock, waitForNextTick, waitUntil } from '@tests/support/utils'
import { AutocompleteSearchOrganizationDocument } from '@shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.api'

const mockQueryResult = (input: {
  query: string
  limit: number
}): AutocompleteSearchOrganizationQuery => {
  const options = testOptions.map((option) =>
    nullableMock({
      ...option,
      labelPlaceholder: null,
      headingPlaceholder: null,
      disabled: null,
      icon: null,
      __typename: 'AutocompleteSearchOrganizationEntry',
    }),
  )

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(input.query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter(
    (option) =>
      filterRegex.test(deaccent(option.label)) ||
      filterRegex.test(deaccent(option.heading)),
  ) as unknown as AutocompleteSearchOrganizationEntry[]

  return {
    autocompleteSearchOrganization: filteredOptions.slice(0, input.limit ?? 25),
  }
}

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
}

const testProps = {
  type: 'organization',
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../../FieldAutoComplete/FieldAutoCompleteInputDialog.vue')
})

describe('Form - Field - Organization - Features', () => {
  it('supports value prefill with existing entity object in root node', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'organization_id',
        name: 'organization_id',
        value: 123,
        belongsToObjectField: 'organization',
      },
    })

    const node = getNode('organization_id')
    node!.context!.initialEntityObject = {
      organization: {
        name: 'Zammad Organization',
        internalId: 123,
      },
    }

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      `Zammad Organization`,
    )
  })
})

// We include only some query-related test cases, since the actual autocomplete component has its own unit test.
describe('Form - Field - Organization - Query', () => {
  let mockApi: MockGraphQLInstance

  beforeEach(() => {
    mockApi = mockGraphQLApi(AutocompleteSearchOrganizationDocument).willBehave(
      (variables) => {
        return {
          data: mockQueryResult(variables.input),
        }
      },
    )
  })

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

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'zammad')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].heading)

    expect(
      queryByIconName(
        selectOptions[0],
        testOptions[0].organization.active
          ? 'mobile-organization'
          : 'mobile-inactive-organization',
      ),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodriguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[7].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[7].heading)

    expect(
      queryByIconName(
        selectOptions[0],
        testOptions[7].organization.active
          ? 'mobile-organization'
          : 'mobile-inactive-organization',
      ),
    ).toBeInTheDocument()

    await wrapper.events.clear(filterElement)

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodríguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[7].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[7].heading)

    expect(
      queryByIconName(
        selectOptions[0],
        testOptions[7].organization.active
          ? 'mobile-organization'
          : 'mobile-inactive-organization',
      ),
    ).toBeInTheDocument()
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

    await wrapper.events.type(filterElement, 'zammad')

    await waitUntil(() => mockApi.calls.behave)

    wrapper.events.click((await wrapper.findAllByRole('option'))[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('mobile-check')).toBeInTheDocument()
  })
})
