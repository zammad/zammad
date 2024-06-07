// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { mockAutocompleteSearchObjectAttributeExternalDataSourceQuery } from '#shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.mocks.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'

const testOptions = [
  {
    label: 'AAA Example',
    value: 'AAA',
  },
  {
    label: 'ABC Example',
    value: 'ABC',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  store: true,
}

const testProps = {
  name: 'test',
  id: 'test',
  type: 'externalDataSource',
  label: 'Select…',
  object: EnumObjectManagerObjects.Ticket,
}

// We include only some query-related test cases, as the actual autocomplete component has its own unit test.
describe('Form - Field - External Data Source - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    const mocker = mockAutocompleteSearchObjectAttributeExternalDataSourceQuery(
      {
        autocompleteSearchObjectAttributeExternalDataSource: testOptions,
      },
    )

    // When we only have one field, the root node is the field itself.
    // So we are faking the initial entity object.
    const ticketId = ensureGraphqlId('Ticket', 123)
    const node = getNode('test')
    node!.context!.initialEntityObject = {
      id: ticketId,
    }

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'A')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    const mockCalls = await mocker.waitForCalls()

    expect(mockCalls).toHaveLength(1)

    expect(mockCalls[0].variables).toEqual({
      input: {
        attributeName: 'test',
        object: EnumObjectManagerObjects.Ticket,
        query: 'A',
        templateRenderContext: {
          ticketId,
        },
      },
    })

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(2)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
  })

  it('correctly renders default value', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: {
          value: '1',
          label: 'Selected Value',
        },
        debounceInterval: 0,
      },
    })

    const input = await wrapper.findByLabelText('Select…')
    expect(input).toHaveTextContent('Selected Value')
  })

  it('supports clear button', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: {
          value: '1',
          label: 'Selected Value',
        },
        clearable: true,
      },
    })

    await vi.waitFor(() => {
      expect(wrapper.getByRole('listitem')).toHaveTextContent('Selected Value')
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    await vi.waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual({})

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })
})
