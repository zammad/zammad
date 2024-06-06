// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode, type FormKitNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import {
  getByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchOrganizationQuery,
  waitForAutocompleteSearchOrganizationQueryCalls,
} from '#shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.mocks.ts'
import type { AutocompleteSearchOrganizationEntry } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

const testOptions: AutocompleteSearchOrganizationEntry[] = [
  {
    __typename: 'AutocompleteSearchOrganizationEntry',
    value: 1,
    label: 'Zammad Foundation',
    labelPlaceholder: [],
    heading: 'autocomplete sample 1',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    organization: nullableMock({
      id: convertToGraphQLId('Organization', 1),
      internalId: 1,
      name: 'Zammad Foundation',
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      vip: true,
      active: true,
      policy: {
        update: true,
        destroy: false,
      },
    }),
  },
  {
    __typename: 'AutocompleteSearchOrganizationEntry',
    value: 2,
    label: 'Zammad Organization',
    labelPlaceholder: [],
    heading: 'autocomplete sample 2',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    organization: nullableMock({
      id: convertToGraphQLId('Organization', 2),
      internalId: 1,
      name: 'Zammad Organization',
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      vip: false,
      active: false,
      policy: {
        update: true,
        destroy: false,
      },
    }),
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'organization',
  label: 'Select…',
}

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
        // Add manually the "initialEntityObject" which is normally coming
        // from the root node (for a single field root node === own node).
        plugins: [
          (node: FormKitNode) => {
            node.context!.initialEntityObject = {
              organization: {
                name: 'Zammad Organization',
                internalId: 123,
              },
            }
          },
        ],
      },
    })

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      'Zammad Organization',
    )

    // Reset the field with new value and before change the initial entity object.
    const node = getNode('organization_id')!
    node.context!.initialEntityObject = {
      organization: {
        internalId: 456,
        name: 'Zammad Foundation',
      },
    }
    node.reset('456')

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Zammad Foundation')
  })
})

// We include only some query-related test cases, since the actual autocomplete component has its own unit test.
describe('Form - Field - Organization - Query', () => {
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

    mockAutocompleteSearchOrganizationQuery({
      autocompleteSearchOrganization: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchOrganizationQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    // Organization with ID 1 should show the buildings icon (active).
    expect(getByIconName(selectOptions[0], 'buildings')).toBeInTheDocument()

    // Organization with ID 1 should have a silver crown (VIP).
    expect(getByIconName(selectOptions[0], 'crown-silver')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    mockAutocompleteSearchOrganizationQuery({
      autocompleteSearchOrganization: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, testOptions[1].label)

    await waitForAutocompleteSearchOrganizationQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)

    // Organization with ID 2 should show the slashed buildings icon (inactive).
    expect(
      getByIconName(selectOptions[0], 'buildings-slash'),
    ).toBeInTheDocument()

    // Organization with ID 2 should not have a silver crown (not VIP).
    expect(
      queryByIconName(selectOptions[0], 'crown-silver'),
    ).not.toBeInTheDocument()
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

    mockAutocompleteSearchOrganizationQuery({
      autocompleteSearchOrganization: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchOrganizationQueryCalls()

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

  it('supports filtering out organizations of a specific user', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        additionalQueryParams: {
          customerId: '999',
        },
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchOrganizationQuery({
      autocompleteSearchOrganization: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, '*')

    const calls = await waitForAutocompleteSearchOrganizationQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        customerId: '999',
      }),
    })
  })
})
