// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import {
  getAllByRole,
  getByRole,
  getByText,
  queryByRole,
  waitFor,
} from '@testing-library/vue'
import { cloneDeep, keyBy } from 'lodash-es'

import {
  findByIconName,
  getByIconName,
  queryAllByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { TreeSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import useFlatSelectOptions from '../useFlatSelectOptions.ts'

const { flattenOptions } = useFlatSelectOptions()

const testOptions: TreeSelectOption[] = [
  {
    value: 0,
    label: 'Item A',
    children: [
      {
        value: 1,
        label: 'Item 1',
        children: [
          {
            value: 2,
            label: 'Item I',
          },
          {
            value: 3,
            label: 'Item II',
          },
          {
            value: 4,
            label: 'Item III',
          },
        ],
      },
      {
        value: 5,
        label: 'Item 2',
        children: [
          {
            value: 6,
            label: 'Item IV',
          },
        ],
      },
      {
        value: 7,
        label: 'Item 3',
      },
    ],
  },
  {
    value: 8,
    label: 'Item B',
  },
  {
    value: 9,
    label: 'Ítem C',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  store: true,
}

const commonProps = {
  label: 'Treeselect',
  type: 'treeselect',
}

describe('Form - Field - TreeSelect - Dropdown', () => {
  it('renders select options in a dropdown menu', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const dropdown = wrapper.getByRole('menu')

    const selectOptions = getAllByRole(dropdown, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.keyboard('{Escape}')

    expect(dropdown).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dropdown', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        clearable: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    await wrapper.events.click(getAllByRole(listbox, 'option')[0])

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
        ...commonProps,
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

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

  it('shows full path of selected options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        value: testOptions[0].children![0].children![0].value,
      },
    })

    const selectedLabel = wrapper.getByRole('listitem')

    expect(selectedLabel).toHaveTextContent(
      `${testOptions[0].label} \u203A ${
        testOptions[0].children![0].label
      } \u203A ${testOptions[0].children![0].children![0].label}`,
    )
  })

  it('supports tree paging', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    // Level 0
    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const dropdown = wrapper.getByRole('menu')

    const listbox = getByRole(dropdown, 'listbox')

    // No back button in root.
    expect(
      queryByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).not.toBeInTheDocument()

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    // Level 1
    await wrapper.events.click(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    )

    expect(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions[0].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label!,
      )
    })

    // Level 2
    await wrapper.events.click(
      getAllByRole(listbox, 'button', { name: 'Has submenu' })[0],
    )

    expect(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(
      testOptions[0].children![0].children!.length,
    )

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![0].children![index].label!,
      )
    })

    // Level 1
    await wrapper.events.click(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    )

    expect(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions[0].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label!,
      )
    })

    // Level 2
    await wrapper.events.click(
      getAllByRole(listbox, 'button', { name: 'Has submenu' })[1],
    )

    expect(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(
      testOptions[0].children![1].children!.length,
    )

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![1].children![index].label!,
      )
    })

    // Level 0
    await wrapper.events.click(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    )

    await wrapper.events.click(
      getByRole(dropdown, 'button', { name: 'Back to previous page' }),
    )

    // No back button in root.
    expect(
      queryByRole(dropdown, 'button', { name: 'Back to previous page' }),
    ).not.toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })
  })
})

describe('Form - Field - TreeSelect - Options', () => {
  it('supports unknown options', async () => {
    const optionsProp = cloneDeep(testOptions)

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 10,
        options: optionsProp,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('10 (unknown)')

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    optionsProp.push({
      value: 10,
      label: 'Item D',
    })

    await wrapper.rerender({
      options: optionsProp,
    })

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    await wrapper.events.click(wrapper.baseElement)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')
  })

  it('supports clearing of the existing value when option goes away', async () => {
    const optionsProp = cloneDeep(testOptions)

    optionsProp.push({
      value: 10,
      label: 'Item D',
    })

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        clearable: true, // otherwise it defaults to the first option
        value: 10,
        options: optionsProp,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')

    optionsProp.pop()

    await wrapper.rerender({
      options: optionsProp,
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(null)
    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
  })

  it('supports historical options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 10,
        options: testOptions,
        historicalOptions: {
          ...keyBy(testOptions, 'value'),
          10: 'Item D',
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    let listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(4)

    selectOptions.forEach((selectOption, index) => {
      if (index === 3) expect(selectOption).toHaveTextContent('Item D')
      else expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)
    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label!,
    )

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    listbox = wrapper.getByRole('listbox')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(4)

    selectOptions.forEach((selectOption, index) => {
      if (index === 3) expect(selectOption).toHaveTextContent('Item D')
      else expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })
  })

  it('supports rejection of non-existent values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 10,
        options: testOptions,
        clearable: true, // otherwise it defaults to the first option
        rejectNonExistentValues: true,
      },
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(null)
    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })
  })

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
        children: [
          {
            value: 3,
            label: 'Item 1',
          },
          {
            value: 4,
            label: 'Item 2',
          },
        ],
      },
      {
        value: 2,
        label: 'Item C',
        disabled: true,
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions[1]).toHaveAttribute('aria-disabled', 'true')
    expect(selectOptions[1].childNodes[2]).toHaveClass('pointer-events-none')

    expect(getByText(listbox, disabledOptions[1].label)).toHaveClasses([
      'text-gray-100',
      'dark:text-neutral-400',
    ])

    expect(selectOptions[2]).toHaveAttribute('aria-disabled', 'true')
    expect(selectOptions[2].childNodes[2]).toHaveClass('pointer-events-none')

    expect(getByText(listbox, disabledOptions[2].label)).toHaveClasses([
      'text-stone-200',
      'dark:text-neutral-500',
    ])

    await wrapper.events.click(getByRole(listbox, 'button'))

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(disabledOptions[1].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        disabledOptions[1].children![index].label,
      )
    })
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
        ...commonProps,
        options: iconOptions,
        clearable: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    expect(queryByIconName(listbox, iconOptions[0].icon)).toBeInTheDocument()
    expect(queryByIconName(listbox, iconOptions[1].icon)).toBeInTheDocument()

    await wrapper.events.click(getAllByRole(listbox, 'option')[0])

    const listitem = wrapper.getByRole('listitem')

    expect(queryByIconName(listitem, iconOptions[0].icon)).toBeInTheDocument()
  })
})

describe('Form - Field - TreeSelect - Features', () => {
  it('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'treeselect',
        options: testOptions,
        clearable: false,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label!,
    )

    const node = getNode('treeselect')
    node?.input(testOptions[2].value)

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[2].label!,
    )
  })

  it('supports selection clearing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
      },
    })

    const listitem = wrapper.getByRole('listitem')

    expect(listitem).toHaveTextContent(testOptions[1].label!)

    const clearSelectionButton = wrapper.getByRole('button', {
      name: 'Clear Selection',
    })

    await wrapper.events.click(clearSelectionButton)

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(null)

    expect(listitem).not.toBeInTheDocument()
    expect(clearSelectionButton).not.toBeInTheDocument()
  })

  it('supports multiple selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        multiple: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const menu = wrapper.getByRole('menu')

    const selectAllButton = getByRole(menu, 'button', {
      name: 'select all options',
    })

    const listbox = getByRole(menu, 'listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectAllButton).toBeInTheDocument()

    expect(selectOptions).toHaveLength(
      queryAllByIconName(listbox, 'square').length,
    )

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])
    expect(selectAllButton).toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(2)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(1)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[1][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(selectAllButton).toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(1)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(2)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[2][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(selectAllButton).toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(0)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(3)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[3][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(selectAllButton).toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(1)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(2)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.events.click(selectAllButton)

    await waitFor(() => {
      expect(emittedInput[4][0]).toStrictEqual(
        flattenOptions(testOptions).map((option) => option.value),
      )
    })

    expect(selectAllButton).not.toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(0)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(3)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(10)

    await wrapper.events.click(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    )

    expect(
      queryByRole(menu, 'button', {
        name: 'select visible options',
      }),
    ).not.toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(emittedInput[5][0]).toStrictEqual(
        flattenOptions(testOptions)
          .map((option) => option.value)
          .filter((value) => value !== testOptions[0].children![0].value),
      )
    })

    const selectVisibleButton = getByRole(menu, 'button', {
      name: 'select visible options',
    })

    await wrapper.events.click(selectVisibleButton)

    await waitFor(() => {
      expect(emittedInput[6][0]).toStrictEqual(
        flattenOptions(testOptions).map((option) => option.value),
      )
    })

    expect(selectVisibleButton).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.baseElement)
  })

  it('supports option sorting', async (context) => {
    context.skipConsole = true

    const reversedOptions = cloneDeep(testOptions).reverse()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: reversedOptions,
        sorting: 'label',
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    await wrapper.rerender({
      sorting: 'value',
    })

    selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label!)
    })

    vi.spyOn(console, 'warn')

    await wrapper.rerender({
      sorting: 'foobar',
    })

    expect(console.warn).toHaveBeenCalledWith(
      'Unsupported sorting option "foobar"',
    )
  })

  it('supports label translation', async () => {
    const untranslatedOptions = [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: [0],
      },
      {
        value: 1,
        label: 'Item B (%s)',
        labelPlaceholder: [1],
      },
      {
        value: 2,
        label: 'Item C (%s)',
        labelPlaceholder: [2],
      },
    ]

    const translatedOptions = untranslatedOptions.map((untranslatedOption) => ({
      ...untranslatedOption,
      label: i18n.t(
        untranslatedOption.label,
        untranslatedOption.labelPlaceholder as never,
      ),
    }))

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: untranslatedOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    let listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(translatedOptions[index].label)
    })

    await wrapper.events.click(selectOptions[0])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      translatedOptions[0].label,
    )

    await wrapper.rerender({
      noOptionsLabelTranslation: true,
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    listbox = wrapper.getByRole('listbox')

    selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
    })

    await wrapper.events.click(selectOptions[1])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[1].label,
    )
  })

  it('supports option pre-select', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'treeselect',
        type: 'treeselect',
        options: testOptions,
      },
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item A')

    await wrapper.rerender({
      clearable: true,
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    )

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.rerender({
      clearable: false,
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item A')

    await wrapper.rerender({
      clearable: true,
    })

    // Reset the value before the next test case
    const node = getNode('treeselect')
    node?.input(null)

    await wrapper.rerender({
      clearable: false,
      options: [
        {
          value: 9,
          label: 'Ítem C',
        },
      ],
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Ítem C')

    await wrapper.rerender({
      clearable: true,
      multiple: true,
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    )

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.rerender({
      clearable: false,
    })

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.rerender({
      clearable: true,
      multiple: false,
      disabled: true,
    })

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.rerender({
      clearable: false,
    })

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
  })

  it('considers only enabled options for pre-selection', async () => {
    const disabledOptions = [
      {
        value: 0,
        label: 'Item A',
        disabled: true,
      },
      {
        value: 1,
        label: 'Item B',
        disabled: true,
        children: [
          {
            value: 3,
            label: 'Item 1',
          },
          {
            value: 4,
            label: 'Item 2',
          },
        ],
      },
      {
        value: 2,
        label: 'Item C',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'treeselect',
        type: 'treeselect',
        options: disabledOptions,
      },
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item 1')
  })

  it('supports option filtering', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    // Without parent filtering, search happens across all options, even nested ones.
    //   Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'iv')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item A › Item 2 › Item IV')

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Search' }),
    )

    expect(filterElement).toHaveValue('')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'item c')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem C')

    await wrapper.events.clear(filterElement)

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'ítem c')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem C')

    await wrapper.events.clear(filterElement)

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    await wrapper.events.click(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    )

    // With parent filtering, search happens only across children and other descendants.
    await wrapper.events.type(filterElement, 'a')

    selectOptions = wrapper.queryAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('No results found')

    await wrapper.events.clear(filterElement)

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label!,
      )
      expect(selectOption).not.toHaveTextContent(`${testOptions[0].label} › `)
    })

    // With parent filtering, search happens only across children and other descendants.
    await wrapper.events.type(filterElement, 'III')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item A › Item 1 › Item III')

    expect(getByText(selectOptions[0], 'III')).toHaveClasses([
      'bg-blue-600',
      'dark:bg-blue-900',
    ])

    await wrapper.rerender({ noFiltering: true })

    expect(filterElement).not.toBeInTheDocument()

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label!,
      )
      expect(selectOption).not.toHaveTextContent(`${testOptions[0].label} › `)
    })
  })

  it('highlights matched text in filtered options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'item')

    const selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption) => {
      if (selectOption.textContent === 'Ítem C') {
        expect(selectOption.children[1].children[0]).toHaveTextContent('Ítem')
      } else {
        expect(selectOption.children[1].children[0]).toHaveTextContent('Item')
      }

      expect(selectOption.children[1].children[0]).toHaveClasses([
        'bg-blue-600',
        'dark:bg-blue-900',
      ])
    })
  })
})

describe('Form - Field - TreeSelect - Accessibility', () => {
  it('supports element focusing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        clearable: true,
        multiple: true,
        value: [testOptions[0].value],
      },
    })

    expect(wrapper.getByLabelText('Treeselect')).toHaveAttribute(
      'tabindex',
      '0',
    )

    const listitem = wrapper.getByRole('listitem')

    expect(
      getByRole(listitem, 'button', { name: 'Unselect Option' }),
    ).toHaveAttribute('tabindex', '0')

    expect(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    ).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

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

    // Sub-menu button is not part of tab-order in order to allow easier selection of options.
    //   Its function can be still triggered via keyboard arrow right/left key.
    const submenuButton = getByRole(listbox, 'button', { name: 'Has submenu' })

    expect(submenuButton).toHaveAttribute('tabindex', '-1')

    await wrapper.events.click(submenuButton)

    expect(
      getByRole(menu, 'button', { name: 'Back to previous page' }),
    ).toHaveAttribute('tabindex', '0')
  })

  it('allows focusing of disabled field for a11y', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Select…',
        type: 'treeselect',
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')
  })

  it('restores focus on close', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        disabled: false,
      },
    })

    const selectButton = wrapper.getByLabelText('Treeselect')

    await wrapper.events.click(selectButton)

    expect(selectButton).not.toHaveFocus()

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    await wrapper.events.type(selectOptions[0], '{Space}')

    expect(selectButton).toHaveFocus()
  })

  it('clicking disabled field does not show dropdown', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('clicking treeselect without options shows an empty dropdown', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const dropdown = wrapper.getByRole('menu')

    const selectOption = getByRole(dropdown, 'option')

    expect(selectOption).toHaveTextContent('No results found')
  })

  it('provides labels for screen readers', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
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
        ...commonProps,
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

    await wrapper.events.keyboard('{ArrowUp}')

    expect(selectOptions[1]).toHaveFocus()

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
describe('Form - Field - TreeSelect - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'test_id',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Treeselect')).toHaveAttribute(
      'id',
      'test_id',
    )
  })

  it('implements input name', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        name: 'test_name',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Treeselect')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        onBlur: blurHandler,
      },
    })

    wrapper.getByLabelText('Treeselect').focus()
    await wrapper.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        clearable: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

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
          ...commonProps,
          options: testOptions,
          value: testOption.value,
        },
      })

      expect(wrapper.getByRole('listitem')).toHaveTextContent(testOption.label!)
    },
  )

  it('implements disabled', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Treeselect')).toHaveAttribute(
      'aria-disabled',
      'true',
    )
  })

  it('implements attribute passthrough', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        'test-attribute': 'test_value',
      },
    })

    expect(wrapper.getByLabelText('Treeselect')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    expect(wrapper.getByTestId('field-treeselect')).toHaveClass('formkit-input')
  })
})

describe('Form - Field - TreeSelect - Visuals', () => {
  it('submenu arrow changes direction when locale changes', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const listbox = wrapper.getByRole('listbox')

    const submenuButton = getByRole(listbox, 'button', { name: 'Has submenu' })

    expect(getByIconName(submenuButton, 'chevron-right')).toBeInTheDocument()

    const locale = useLocaleStore()
    locale.localeData = {
      dir: EnumTextDirection.Rtl,
    } as any

    await expect(
      findByIconName(submenuButton, 'chevron-right'),
    ).resolves.toBeInTheDocument()
  })

  it('back button arrow changes direction when locale changes', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Treeselect'))

    const dropdown = wrapper.getByRole('menu')

    const listbox = getByRole(dropdown, 'listbox')

    await wrapper.events.click(
      getByRole(listbox, 'button', { name: 'Has submenu' }),
    )

    expect(getByIconName(dropdown, 'chevron-left')).toBeInTheDocument()

    const locale = useLocaleStore()
    locale.localeData = {
      dir: EnumTextDirection.Rtl,
    } as any

    await expect(
      findByIconName(dropdown, 'chevron-right'),
    ).resolves.toBeInTheDocument()
  })
})
