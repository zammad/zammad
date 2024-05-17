// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { AutocompleteSearchObjectAttributeExternalDataSourceDocument } from '#shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.api.ts'
import {
  EnumObjectManagerObjects,
  type AutocompleteSearchObjectAttributeExternalDataSourceQuery,
} from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  name: 'test',
  id: 'test',
  type: 'externalDataSource',
  label: 'Select…',
  object: EnumObjectManagerObjects.Ticket,
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../../FieldAutoComplete/FieldAutoCompleteInputDialog.vue')
})

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

    // When we only have one field, the root node is the field itself.
    // So we are faking the initial entity object.
    const ticketId = ensureGraphqlId('Ticket', 123)
    const node = getNode('test')
    node!.context!.initialEntityObject = {
      id: ticketId,
    }

    // Resolve `defineAsyncComponent()` calls first.
    await vi.dynamicImportSettled()

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'a')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    const callResult = await vi.waitUntil(
      () =>
        getGraphQLMockCalls<AutocompleteSearchObjectAttributeExternalDataSourceQuery>(
          AutocompleteSearchObjectAttributeExternalDataSourceDocument,
        ).at(-1)!,
    )

    const testOptions =
      callResult.result.autocompleteSearchObjectAttributeExternalDataSource

    expect(callResult.variables).toMatchObject({
      input: {
        attributeName: 'test',
        object: EnumObjectManagerObjects.Ticket,
        query: 'a',
        templateRenderContext: {
          ticketId,
        },
      },
    })

    expect(testOptions.length).toBeGreaterThan(0)

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((option, index) => {
      expect(option).toHaveTextContent(testOptions[index].label)
      expect(option).toHaveTextContent(testOptions[index].heading)
    })

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    await vi.waitFor(() => {
      expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    })

    // // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'r')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    const newTestOptions = await vi.waitFor(
      () =>
        getGraphQLMockCalls<AutocompleteSearchObjectAttributeExternalDataSourceQuery>(
          AutocompleteSearchObjectAttributeExternalDataSourceDocument,
        ).at(-1)!.result.autocompleteSearchObjectAttributeExternalDataSource,
    )

    expect(newTestOptions[0].value).not.toBe(testOptions[0].value)

    selectOptions.forEach((option, index) => {
      expect(option).toHaveTextContent(newTestOptions[index].label)
      expect(option).toHaveTextContent(newTestOptions[index].heading)
    })
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
