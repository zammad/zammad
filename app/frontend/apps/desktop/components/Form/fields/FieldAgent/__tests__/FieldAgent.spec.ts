// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode, type FormKitNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getByTestId, waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import logo from '#shared/components/CommonUserAvatar/assets/logo.svg'
import {
  mockAutocompleteSearchAgentQuery,
  waitForAutocompleteSearchAgentQueryCalls,
} from '#shared/components/Form/fields/FieldAgent/graphql/queries/autocompleteSearch/agent.mocks.ts'
import type { AutocompleteSearchUserEntry } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

const testOptions: AutocompleteSearchUserEntry[] = [
  {
    __typename: 'AutocompleteSearchUserEntry',
    value: 0,
    label: 'foo',
    labelPlaceholder: [],
    heading: 'autocomplete sample 1',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    user: nullableMock({
      id: convertToGraphQLId('User', 1),
      internalId: 1,
      fullname: 'sample 1',
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      policy: {
        update: true,
        destroy: false,
      },
    }),
  },
  {
    __typename: 'AutocompleteSearchUserEntry',
    value: 1,
    label: 'bar',
    labelPlaceholder: [],
    heading: 'autocomplete sample 2',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    user: nullableMock({
      id: convertToGraphQLId('User', 2),
      internalId: 2,
      fullname: 'sample 2',
      image:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//2/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==',
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
      policy: {
        update: true,
        destroy: false,
      },
    }),
  },
  {
    __typename: 'AutocompleteSearchUserEntry',
    value: 2,
    label: 'baz',
    labelPlaceholder: [],
    heading: 'autocomplete sample 3',
    headingPlaceholder: [],
    disabled: false,
    icon: null,
    user: nullableMock({
      id: convertToGraphQLId('User', 3),
      internalId: 3,
      firstname: 'foo',
      lastname: 'bar',
      fullname: 'sample 3',
      image: null,
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
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
  store: true,
}

const testProps = {
  type: 'agent',
  label: 'Select…',
}

describe('Form - Field - Agent - Features', () => {
  it('supports value prefill with existing entity object in root node', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'agent',
        name: 'agent_id',
        value: 123,
        belongsToObjectField: 'user',
        // Add manually the "initialEntityObject" which is normally coming
        // from the root node (for a single field root node === own node).
        plugins: [
          (node: FormKitNode) => {
            node.context!.initialEntityObject = {
              user: {
                internalId: 123,
                fullname: 'John Doe',
              },
            }
          },
        ],
      },
    })

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('John Doe')

    // Reset the field with new value and before change the initial entity object.
    const node = getNode('agent')!
    node.context!.initialEntityObject = {
      user: {
        internalId: 456,
        fullname: 'Jane Doe',
      },
    }
    node.reset('456')

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Jane Doe')
  })
})

describe('Form - Field - Agent - Query', () => {
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

    mockAutocompleteSearchAgentQuery({
      autocompleteSearchAgent: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchAgentQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    // User with ID 1 should show the logo.
    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      backgroundImage: `url(/${logo})`,
    })

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchAgentQuery({
      autocompleteSearchAgent: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, testOptions[1].label)

    await waitForAutocompleteSearchAgentQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[1].user.image})`,
    })

    await wrapper.events.clear(filterElement)

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchAgentQuery({
      autocompleteSearchAgent: [testOptions[2]],
    })

    await wrapper.events.type(filterElement, testOptions[2].label)

    await waitForAutocompleteSearchAgentQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveTextContent(
      'fb',
    )
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

    mockAutocompleteSearchAgentQuery({
      autocompleteSearchAgent: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchAgentQueryCalls()

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
        exceptUserInternalId: 999,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchAgentQuery({
      autocompleteSearchAgent: [...testOptions.slice(0, 1)],
    })

    await wrapper.events.type(filterElement, '*')

    const calls = await waitForAutocompleteSearchAgentQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        exceptInternalId: 999,
      }),
    })
  })
})
