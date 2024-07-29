// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchTagQuery,
  waitForAutocompleteSearchTagQueryCalls,
} from '#shared/entities/tags/graphql/queries/autocompleteTags.mocks.ts'
import type { AutocompleteSearchEntry } from '#shared/graphql/types.ts'

const testOptions: AutocompleteSearchEntry[] = [
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 1',
    label: 'tag 1',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 2',
    label: 'tag 2',
  },
  {
    __typename: 'AutocompleteSearchEntry',
    value: 'tag 3',
    label: 'tag 3',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  store: true,
}

const testProps = {
  type: 'tags',
  label: 'Select…',
}

describe('Form - Field - Tags - Features', () => {
  it('supports adding and removing of new tags', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        clearable: true,
        canCreate: true,
      },
    })

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [],
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    await waitForAutocompleteSearchTagQueryCalls()

    expect(
      wrapper.getByText('Start typing to search or enter a new tag…'),
    ).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'tag')

    await waitForAutocompleteSearchTagQueryCalls()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'add new tag' }),
    )

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual(['tag'])
    expect(wrapper.getByRole('menu')).toBeInTheDocument()
    expect(wrapper.getByRole('listitem')).toHaveTextContent('tag')

    await wrapper.events.keyboard('{Escape}')

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    )

    expect(emittedInput[1][0]).toBeNull()
    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
  })

  it('prevents adding new tags when the setting is disabled', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        canCreate: false,
      },
    })

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [],
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    await waitForAutocompleteSearchTagQueryCalls()

    expect(wrapper.getByText('Start typing to search…')).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'tag')

    await waitForAutocompleteSearchTagQueryCalls()

    expect(
      wrapper.queryByRole('button', { name: 'add new tag' }),
    ).not.toBeInTheDocument()
  })

  it.todo('supports selecting tags via keyboard shortcuts', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        clearable: true,
        canCreate: true,
      },
    })

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [],
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    await waitForAutocompleteSearchTagQueryCalls()

    expect(
      wrapper.getByText('Start typing to search or enter a new tag…'),
    ).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'tag,') // comma

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual(['tag'])

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [testOptions[0]],
    })

    // :TODO fix test
    await wrapper.events.type(filterElement, 'tag 1') // enter

    expect(emittedInput[1][0]).toEqual(['tag', 'tag 1'])

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, 'tag 2{Tab}') // tab

    expect(await wrapper.findByText('tag 2')).toBeInTheDocument()

    expect(emittedInput[2][0]).toEqual(['tag', 'tag 1', 'tag 2'])
  })
})

describe('Form - Field - Tags - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: testOptions,
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    await waitForAutocompleteSearchTagQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'tag')

    await waitForAutocompleteSearchTagQueryCalls()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
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

    mockAutocompleteSearchTagQuery({
      autocompleteSearchTag: testOptions,
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    await waitForAutocompleteSearchTagQueryCalls()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'tag')

    await waitForAutocompleteSearchTagQueryCalls()

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])

    expect(wrapper.queryByRole('menu')).toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    expect(wrapper.getByIconName('check-square')).toBeInTheDocument()
  })
})
