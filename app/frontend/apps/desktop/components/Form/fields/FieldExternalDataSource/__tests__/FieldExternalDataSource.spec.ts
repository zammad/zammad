// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

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

    const mocker = mockAutocompleteSearchObjectAttributeExternalDataSourceQuery({
      autocompleteSearchObjectAttributeExternalDataSource: testOptions,
    })

    // When we only have one field, the root node is the field itself.
    // So we are faking the initial entity object.
    const ticketId = ensureGraphqlId('Ticket', 123)
    const node = getNode('test')
    node!.context!.initialEntityObject = {
      id: ticketId,
    }

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(await wrapper.findByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'A')

    expect(wrapper.queryByText('Start typing to search…')).not.toBeInTheDocument()

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

    await wrapper.events.click(wrapper.getByLabelText('Clear search'))

    expect(filterElement).toHaveValue('')

    expect(await wrapper.findByText('Start typing to search…')).toBeInTheDocument()
  })

  it.each([false, true])('correctly renders default value (multiple: %s)', async (multiple) => {
    const value = multiple ? [testOptions[0]] : testOptions[0]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value,
        options: [testOptions[0]],
        multiple,
      },
    })

    const input = await wrapper.findByLabelText('Select…')

    expect(input).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(input)

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    if (multiple) {
      expect(getByIconName(selectOptions[0], 'check-square')).toBeInTheDocument()
    } else {
      expect(getByIconName(selectOptions[0], 'check2')).toBeInTheDocument()
    }
  })

  it('can select/unselect multiple options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        multiple: true,
      },
    })

    const input = await wrapper.findByLabelText('Select…')

    expect(input).not.toHaveTextContent(testOptions[0].label)
    expect(input).not.toHaveTextContent(testOptions[1].label)

    await wrapper.events.click(input)

    const selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toHaveLength(1)
    })

    let emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual([testOptions[0]])

    expect(input).toHaveTextContent(testOptions[0].label)
    expect(input).not.toHaveTextContent(testOptions[1].label)

    await wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toHaveLength(2)
    })

    emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[1][0]).toEqual(testOptions)

    expect(input).toHaveTextContent(testOptions[0].label)
    expect(input).toHaveTextContent(testOptions[1].label)

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toHaveLength(3)
    })

    emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[2][0]).toEqual([testOptions[1]])

    expect(input).not.toHaveTextContent(testOptions[0].label)
    expect(input).toHaveTextContent(testOptions[1].label)

    await wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toHaveLength(4)
    })

    emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[3][0]).toEqual([])

    expect(input).not.toHaveTextContent(testOptions[0].label)
    expect(input).not.toHaveTextContent(testOptions[1].label)
  })

  it.each([false, true])('supports clearing selection (multiple: %s)', async (multiple) => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: multiple ? [testOptions[0]] : testOptions[0],
        clearable: true,
        multiple,
      },
    })

    await waitFor(() => {
      expect(wrapper.getByRole('listitem')).toHaveTextContent(testOptions[0].label)
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Clear selection' }))

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual(multiple ? [] : {})

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })
})
