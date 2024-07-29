// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import {
  getAllByRole,
  getByRole,
  getByText,
  waitFor,
} from '@testing-library/vue'
import { cloneDeep } from 'lodash-es'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import { AutocompleteSearchUserDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'
import {
  mockAutocompleteSearchUserQuery,
  waitForAutocompleteSearchUserQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.mocks.ts'
import type { AutocompleteSearchUserEntry } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

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
      fullname: 'sample 3',
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
  dialog: true,
  store: true,
}

const testProps = {
  label: 'Select…',
  type: 'autocomplete',
  gqlQuery: AutocompleteSearchUserDocument,
}

describe('Form - Field - AutoComplete - Dropdown', () => {
  it('renders select options in a dropdown menu', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const dropdown = wrapper.getByRole('menu')

    const selectOptions = getAllByRole(dropdown, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
      expect(selectOption).toHaveTextContent(testOptions[index].heading!)
    })

    await wrapper.events.keyboard('{Escape}')

    expect(dropdown).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dropdown', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const listbox = wrapper.getByRole('listbox')

    wrapper.events.click(getAllByRole(listbox, 'option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(listbox).not.toBeInTheDocument()
  })

  it('renders selected option with a check mark icon', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(
      wrapper.getByIconName((name, node) => {
        return (
          name === '#icon-check2' &&
          !node?.parentElement?.classList.contains('invisible')
        )
      }),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.baseElement)

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    await waitForAutocompleteSearchUserQueryCalls()

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Search' }),
    )

    expect(filterElement).toHaveValue('')

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: [testOptions[1]],
    })

    await wrapper.events.type(filterElement, testOptions[1].label)

    await waitForAutocompleteSearchUserQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)

    await wrapper.events.clear(filterElement)

    expect(
      await wrapper.findByText('Start typing to search…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: [testOptions[2]],
    })

    await wrapper.events.type(filterElement, testOptions[2].label)

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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchUserQueryCalls()

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

  it('restores selection on mixing initial and fetched options (multiple)', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: [testOptions[2].value],
        options: [testOptions[2]],
        multiple: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[0], 'check-square')).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: testOptions,
    })

    await wrapper.events.type(filterElement, 'item')

    await waitForAutocompleteSearchUserQueryCalls()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[2], 'check-square')).toBeInTheDocument()

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([
      testOptions[0].value,
      testOptions[2].value,
    ])

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(getByIconName(selectOptions[0], 'check-square')).toBeInTheDocument()
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(getByIconName(selectOptions[1], 'square')).toBeInTheDocument()
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[2], 'check-square')).toBeInTheDocument()
  })

  it('supports storing complex non-multiple values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'autocomplete',
        id: 'autocomplete',
        complexValue: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: [testOptions[0]],
    })

    await wrapper.events.type(filterElement, testOptions[0].label)

    await waitForAutocompleteSearchUserQueryCalls()

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(selectOptions[0])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    const node = getNode('autocomplete')

    expect(node?._value).toEqual({
      value: testOptions[0].value,
      label: testOptions[0].label,
    })
  })

  it('supports storing complex multiple values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'autocomplete',
        id: 'autocomplete',
        multiple: true,
        complexValue: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: testOptions,
    })

    await wrapper.events.type(filterElement, '*')

    await waitForAutocompleteSearchUserQueryCalls()

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)

    await wrapper.events.click(selectOptions[0])

    await wrapper.events.type(filterElement, '*')

    await waitForAutocompleteSearchUserQueryCalls()

    selectOptions = getAllByRole(listbox, 'option')

    await wrapper.events.click(selectOptions[1])

    const [item1, item2] = wrapper.getAllByRole('listitem')

    expect(item1).toHaveTextContent(testOptions[0].label)
    expect(item2).toHaveTextContent(testOptions[1].label)

    const node = getNode('autocomplete')

    expect(node?._value).toEqual([
      {
        value: testOptions[0].value,
        label: testOptions[0].label,
      },
      {
        value: testOptions[1].value,
        label: testOptions[1].label,
      },
    ])
  })

  it('supports passing additional query parameters', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        additionalQueryParams: {
          limit: 2,
        },
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: testOptions,
    })

    await wrapper.events.type(wrapper.getByRole('searchbox'), '*')

    const calls = await waitForAutocompleteSearchUserQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        limit: 2,
      }),
    })
  })

  it('supports default filter for initial query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        defaultFilter: '*',
        multiple: true,
      },
    })

    mockAutocompleteSearchUserQuery({
      autocompleteSearchUser: testOptions,
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const calls = await waitForAutocompleteSearchUserQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        query: '*',
      }),
    })

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)

    // Replaces default filter query with selection.
    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getAllByRole('option')[1]).toHaveAttribute(
      'aria-disabled',
      'true',
    )

    expect(
      getByText(wrapper.getByRole('listbox'), disabledOptions[1].label),
    ).toHaveClass('text-stone-200 dark:text-neutral-500')
  })

  it('supports icon property', async () => {
    const iconOptions = [
      {
        value: 1,
        label: 'GitLab',
        icon: 'gitlab',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'github',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: iconOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByIconName(iconOptions[0].icon)).toBeInTheDocument()
    expect(wrapper.queryByIconName(iconOptions[1].icon)).toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Features', () => {
  it('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'autocomplete',
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    const node = getNode('autocomplete')

    node?.input(testOptions[2].value)

    await waitForNextTick(true)

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

    expect(emittedInput[0][0]).toBe(null)

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })

  it('supports custom clear value', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
        clearValue: {},
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

    expect(emittedInput[0][0]).toEqual({})

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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      wrapper.queryAllByIconName('square').length,
    )

    wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])
    expect(wrapper.queryAllByIconName('square')).toHaveLength(2)
    expect(wrapper.queryAllByIconName('check-square')).toHaveLength(1)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[1][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('square')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('check-square')).toHaveLength(2)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[2][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(wrapper.queryAllByIconName('square')).toHaveLength(0)
    expect(wrapper.queryAllByIconName('check-square')).toHaveLength(3)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[3][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('square')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('check-square')).toHaveLength(2)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })
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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[2].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[0].label)

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
        label: 'Item C',
        heading: 'autocomplete sample',
      },
    ]

    i18n.setTranslationMap(
      new Map([
        ['Item C', 'Translated Item C'],
        ['autocomplete sample', 'translated autocomplete sample'],
      ]),
    )

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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        `${translatedOptions[index].label} – ${translatedOptions[index].heading}`,
      )
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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      // Forces translation due to placeholder availability.
      if (untranslatedOptions[index].labelPlaceholder) {
        expect(selectOption).toHaveTextContent(
          `${translatedOptions[index].label} – ${translatedOptions[index].heading}`,
        )
      } else {
        expect(selectOption).toHaveTextContent(
          `${untranslatedOptions[index].label} – ${untranslatedOptions[index].heading}`,
        )
      }
    })

    await wrapper.events.click(selectOptions[2])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[2].label,
    )
  })

  it('supports value prefill with initial option builder', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: 1234,
        initialOptionBuilder: (object: ObjectLike, value: SelectValue) => {
          return {
            value,
            label: `Item ${value}`,
          }
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(`Item 1234`)
  })

  it('supports non-multiple complex value', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: {
          value: 1234,
          label: 'Item 1234',
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item 1234')
  })

  it('supports multiple complex value', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        multiple: true,
        value: [
          {
            value: 1234,
            label: 'Item 1234',
          },
          {
            value: 4321,
            label: 'Item 4321',
          },
        ],
      },
    })

    const [item1, item2] = wrapper.getAllByRole('listitem')

    expect(item1).toHaveTextContent('Item 1234')
    expect(item2).toHaveTextContent('Item 4321')
  })

  it('can add custom dropdown actions', async () => {
    const actionCallbackSpy = vi.fn()
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        actions: [
          {
            key: 'custom-action',
            label: 'Custom Action',
            onClick: actionCallbackSpy,
          },
        ],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))
    await wrapper.events.click(wrapper.getByText('Custom Action'))

    expect(actionCallbackSpy).toHaveBeenCalledTimes(1)
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
        multiple: true,
        value: [testOptions[0].value],
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')

    const listitem = wrapper.getByRole('listitem')

    expect(
      getByRole(listitem, 'button', { name: 'Unselect Option' }),
    ).toHaveAttribute('tabindex', '0')

    expect(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    ).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const menu = wrapper.getByRole('menu')

    const selectAllButton = getByRole(menu, 'button', {
      name: 'select all options',
    })

    expect(selectAllButton).toHaveAttribute('tabindex', '0')

    const listbox = getByRole(menu, 'listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption) => {
      expect(selectOption).toHaveAttribute('tabindex', '0')
    })
  })

  it('keeps focus after select', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    const selectField = wrapper.getByLabelText('Select…')

    await wrapper.events.click(selectField)

    expect(selectField).not.toHaveFocus()

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    await wrapper.events.type(selectOptions[0], '{Space}')

    expect(selectField).toHaveFocus()
  })

  it('allows focusing of disabled field for a11y', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')
  })

  it('prevents opening of dropdown in disabled field', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('shows a hint in case there are no options available', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveAttribute('aria-disabled', 'true')
    expect(selectOptions[0]).toHaveTextContent('Start typing to search…')
  })

  it('shows the provided hint in case there are no options available', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        emptyInitialLabelText: 'Custom Text',
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveAttribute('aria-disabled', 'true')
    expect(selectOptions[0]).toHaveTextContent('Custom Text')
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

    await wrapper.events.keyboard('{Tab}{Enter}')

    const menu = wrapper.getByRole('menu')

    expect(menu).toBeInTheDocument()

    const search = wrapper.getByRole('searchbox')

    expect(search).toHaveFocus()

    await wrapper.events.type(search, '{Down}')

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions[1]).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')

    expect(selectOptions[2]).toHaveFocus()

    await wrapper.events.type(selectOptions[2], '{Space}')

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[2].value)

    wrapper.events.type(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
      '{Space}',
    )

    await waitFor(() => {
      expect(emittedInput[1][0]).toBe(null)
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
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('id', 'test_id')
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

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute(
      'name',
      'test_name',
    )
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

    wrapper.getByLabelText('Select…').focus()
    await wrapper.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

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

    expect(wrapper.getByLabelText('Select…')).toHaveClass(
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

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute(
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
