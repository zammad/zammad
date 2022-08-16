// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep, escapeRegExp } from 'lodash-es'
import { getByText, waitFor } from '@testing-library/vue'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { i18n } from '@shared/i18n'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import { AutocompleteSearchUserDocument } from '@shared/graphql/queries/autocompleteSearch/user.api'
import type { AutocompleteSearchUserQuery } from '@shared/graphql/types'

const testOptions = [
  {
    value: 0,
    label: 'Item A',
    heading: 'autocomplete sample 1',
  },
  {
    value: 1,
    label: 'Item B',
    heading: 'autocomplete sample 2',
  },
  {
    value: 2,
    label: 'Ítem C',
    heading: 'autocomplete sample 3',
  },
]

const mockQueryResult = (
  query: string,
  limit: number,
): AutocompleteSearchUserQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
    icon: null,
    __typename: 'AutocompleteEntry',
  }))

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter((option) =>
    filterRegex.test(deaccent(option.label)),
  ) as unknown as {
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    disabled?: boolean | null
    icon?: string | null
  }[]

  return {
    autocompleteSearchUser: filteredOptions.slice(0, limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchUserDocument,
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
  type: 'autocomplete',
  gqlQuery: `
query autocompleteSearchUser($query: String!, $limit: Int) {
  autocompleteSearchUser(query: $query, limit: $limit) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
`,
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../FieldAutoCompleteInputDialog.vue')
})

describe('Form - Field - AutoComplete - Dialog', () => {
  it('renders select options in a modal dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
      expect(selectOption).toHaveTextContent(testOptions[index].heading)
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('renders selected option in semibold text with a check mark icon', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getByIconName('check')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Query', () => {
  mockClient()

  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'a')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'item c')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)

    await wrapper.events.clear(filterElement)

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()
    expect(wrapper.queryByRole('option')).not.toBeInTheDocument()

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'ítem c')

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

    await wrapper.events.click(wrapper.getByRole('list'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'a')

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

describe('Form - Field - AutoComplete - Initial Options', () => {
  it('supports disabled property', async () => {
    const disabledOptions = [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
        disabled: true,
      },
      {
        value: 2,
        label: 'Item C',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getAllByRole('option')[1]).toHaveClass('pointer-events-none')

    expect(
      getByText(wrapper.getByRole('listbox'), disabledOptions[1].label),
    ).toHaveClass('opacity-30')
  })

  it('supports icon property', async () => {
    const iconOptions = [
      {
        value: 1,
        label: 'GitLab',
        icon: 'gitlab-logo',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'github-logo',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: iconOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.queryByIconName(iconOptions[0].icon)).toBeInTheDocument()
    expect(wrapper.queryByIconName(iconOptions[1].icon)).toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Features', () => {
  // FIXME: Updating value prop does not seem to mutate it.
  //   It could be a bug in FormKit, though. Retry with next release.
  it.todo('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    await wrapper.rerender({
      value: testOptions[2].value,
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[2].label,
    )
  })

  it('supports selection clearing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(undefined)

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })

  it('supports multiple selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        multiple: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      wrapper.queryAllByIconName('checked-no').length,
    )

    wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])
    expect(wrapper.queryAllByIconName('checked-no')).toHaveLength(2)
    expect(wrapper.queryAllByIconName('checked-yes')).toHaveLength(1)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[0][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('checked-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('checked-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[0][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(wrapper.queryAllByIconName('checked-no')).toHaveLength(0)
    expect(wrapper.queryAllByIconName('checked-yes')).toHaveLength(3)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[0][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('checked-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('checked-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(wrapper.getByRole('button'))
  })

  it('supports option sorting', async (context) => {
    context.skipConsole = true

    const reversedOptions = cloneDeep(testOptions).reverse()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: reversedOptions,
        sorting: 'label',
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.rerender({
      sorting: 'value',
    })

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {
      // no-op, silence warnings on the console
    })

    await wrapper.rerender({
      sorting: 'foobar',
    })

    expect(warn).toHaveBeenCalledWith('Unsupported sorting option "foobar"')
  })

  it('supports label translation', async () => {
    const untranslatedOptions = [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: [0],
        heading: 'autocomplete sample %s',
        headingPlaceholder: [1],
      },
      {
        value: 1,
        label: 'Item B (%s)',
        labelPlaceholder: [1],
        heading: 'autocomplete sample %s',
        headingPlaceholder: [2],
      },
      {
        value: 2,
        label: 'Item C (%s)',
        labelPlaceholder: [2],
        heading: 'autocomplete sample %s',
        headingPlaceholder: [3],
      },
    ]

    const translatedOptions = untranslatedOptions.map((untranslatedOption) => ({
      ...untranslatedOption,
      label: i18n.t(
        untranslatedOption.label,
        untranslatedOption.labelPlaceholder as never,
      ),
      heading: i18n.t(
        untranslatedOption.heading,
        untranslatedOption.headingPlaceholder as never,
      ),
    }))

    let wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: untranslatedOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(translatedOptions[index].label)
      expect(selectOption).toHaveTextContent(translatedOptions[index].heading)
    })

    await wrapper.events.click(selectOptions[0])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      translatedOptions[0].label,
    )

    wrapper.unmount()

    wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: untranslatedOptions,
        noOptionsLabelTranslation: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
      expect(selectOption).toHaveTextContent(untranslatedOptions[index].heading)
    })

    await wrapper.events.click(selectOptions[1])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[1].label,
    )
  })

  it('supports option autoselect', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: [
          {
            value: 1,
            label: 'The One',
          },
        ],
        autoselect: true,
      },
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(1)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('The One')
  })

  it('supports additional action', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        action: '/route',
        actionIcon: 'web',
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getByIconName('web')).toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Accessibility', () => {
  it('supports element focusing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[0].value,
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute('tabindex', '0')

    expect(wrapper.getByRole('button')).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByRole('list'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption) => {
      expect(selectOption).toHaveAttribute('tabindex', '0')
    })
  })

  it('prevents focusing of disabled field', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute('tabindex', '-1')
  })

  it('provides labels for screen readers', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute('aria-label', 'Select…')

    expect(wrapper.getByRole('button')).toHaveAttribute(
      'aria-label',
      'Clear Selection',
    )
  })

  it('supports keyboard navigation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.type(wrapper.getByRole('list'), '{Space}')

    const selectOptions = wrapper.getAllByRole('option')

    wrapper.events.type(selectOptions[0], '{Space}')

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    wrapper.events.type(wrapper.getByRole('button'), '{Space}')

    await waitFor(() => {
      expect(emittedInput[1][0]).toBe(undefined)
    })
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/advanced/custom-inputs#input-checklist
describe('Form - Field - AutoComplete - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'test_id',
        label: 'Test label',
        options: testOptions,
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute('id', 'test_id')

    expect(wrapper.getByLabelText('Test label')).toHaveAttribute(
      'id',
      'test_id',
    )
  })

  it('implements input name', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'test_name',
        options: testOptions,
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute('name', 'test_name')
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        onBlur: blurHandler,
      },
    })

    wrapper.getByRole('list').focus()
    await wrapper.events.tab()

    expect(blurHandler).toHaveBeenCalled()
  })

  it('implements input handler', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    wrapper.events.click(wrapper.getAllByRole('option')[1])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[1].value)
  })

  it.each([0, 1, 2])(
    'implements input value display',
    async (testOptionsIndex) => {
      const testOption = testOptions[testOptionsIndex]

      const wrapper = renderComponent(FormKit, {
        ...wrapperParameters,
        props: {
          ...testProps,
          options: testOptions,
          value: testOption.value,
        },
      })

      expect(wrapper.getByRole('listitem')).toHaveTextContent(testOption.label)
    },
  )

  it('implements disabled', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByRole('list')).toHaveClass(
      'formkit-disabled:pointer-events-none',
    )
  })

  it('implements attribute passthrough', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        'test-attribute': 'test_value',
      },
    })

    expect(wrapper.getByRole('list')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    expect(wrapper.getByTestId('field-autocomplete')).toHaveClass(
      'formkit-input',
    )
  })
})
