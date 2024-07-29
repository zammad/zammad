// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import {
  getAllByRole,
  getByRole,
  getByText,
  waitFor,
} from '@testing-library/vue'
import { cloneDeep, keyBy } from 'lodash-es'

import {
  queryAllByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { SetRequired } from 'type-fest'

const testOptions: SetRequired<SelectOption, 'label'>[] = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
}

const commonProps = {
  label: 'Select',
  type: 'select',
}

describe('Form - Field - Select - Dropdown', () => {
  it('renders select options in a dropdown menu', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const dropdown = wrapper.getByRole('menu')

    const selectOptions = getAllByRole(dropdown, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
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
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

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

describe('Form - Field - Select - Options', () => {
  it('supports unknown options', async () => {
    const optionsProp = cloneDeep(testOptions)

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 3,
        options: optionsProp,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('3 (unknown)')

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    optionsProp.push({
      value: 3,
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
      value: 3,
      label: 'Item D',
    })

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        clearable: true, // otherwise it defaults to the first option
        value: 3,
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

  it('supports clearing of the existing multiple values when options go away', async () => {
    const optionsProp = cloneDeep(testOptions)

    optionsProp.push(
      ...[
        {
          value: 3,
          label: 'Item D',
        },
        {
          value: 4,
          label: 'Item E',
        },
      ],
    )

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: [2, 3, 4],
        options: optionsProp,
        multiple: true,
      },
    })

    expect(wrapper.getAllByRole('listitem')).toHaveLength(3)

    await wrapper.rerender({
      options: testOptions,
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual([2])
    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item C')
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
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions[1]).toHaveAttribute('aria-disabled', 'true')

    expect(getByText(listbox, disabledOptions[1].label)).toHaveClasses([
      'text-stone-200',
      'dark:text-neutral-500',
    ])
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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    expect(queryByIconName(listbox, iconOptions[0].icon)).toBeInTheDocument()
    expect(queryByIconName(listbox, iconOptions[1].icon)).toBeInTheDocument()

    await wrapper.events.click(getAllByRole(listbox, 'option')[0])

    const listitem = wrapper.getByRole('listitem')

    expect(queryByIconName(listitem, iconOptions[0].icon)).toBeInTheDocument()
  })

  it('supports historical options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 3,
        options: testOptions,
        historicalOptions: {
          ...keyBy(testOptions, 'value'),
          3: 'Item D',
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    let listbox = wrapper.getByRole('listbox')

    let selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length + 1)

    selectOptions.forEach((selectOption, index) => {
      if (index === 3) expect(selectOption).toHaveTextContent('Item D')
      else expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)
    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    listbox = wrapper.getByRole('listbox')

    selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length + 1)

    selectOptions.forEach((selectOption, index) => {
      if (index === 3) expect(selectOption).toHaveTextContent('Item D')
      else expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })

  it('supports rejection of non-existent values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        value: 3,
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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })

  it('removes value for non-existent option on value update (single)', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        value: 1,
        options: testOptions,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item B')

    // Change values with one which does not exist inside the options (e.g. coming from core workflow).
    const node = getNode('select')
    await node?.settled
    node?.input(3)

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item B')
  })

  it('removes values for non-existent options on value update (multiple)', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        value: [1, 2],
        options: testOptions,
        multiple: true,
      },
    })

    expect(wrapper.getAllByRole('listitem')).toHaveLength(2)

    // Change values with one which not exists inside the options (e.g. coming from core workflow).
    const node = getNode('select')
    await node?.settled
    node?.input([2, 3])

    await waitForNextTick(true)

    expect(wrapper.getAllByRole('listitem')).toHaveLength(1)
  })

  it('pre-selects also on value change when init value no longer exists in options (and pre-select mode is active)', async () => {
    const optionsProp = cloneDeep(testOptions)

    optionsProp.push({
      value: 3,
      label: 'Item D',
    })

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        value: 1,
        options: optionsProp,
      },
    })

    await wrapper.rerender({
      options: [optionsProp[0], optionsProp[2]],
    })

    // Change values with one which not exists inside the options (e.g. coming from core workflow).
    const node = getNode('select')
    await node?.settled
    node?.input(3)

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item A')
  })

  it('removes values for disabled options on value update (multiple)', async () => {
    const optionsProp = cloneDeep(testOptions)
    optionsProp[2].disabled = true

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        value: [0, 1],
        options: optionsProp,
        multiple: true,
      },
    })

    expect(wrapper.getAllByRole('listitem')).toHaveLength(2)

    // Change values with one which not exists inside the options (e.g. coming from core workflow).
    const node = getNode('select')
    await node?.settled
    node?.input([1, 2])

    await waitForNextTick(true)

    expect(wrapper.getAllByRole('listitem')).toHaveLength(1)
  })

  it('removes values for disabled options on initial value (multiple)', async () => {
    const optionsProp = cloneDeep(testOptions)
    optionsProp[2].disabled = true

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        type: 'select',
        value: [0, 1, 2],
        options: optionsProp,
        multiple: true,
      },
    })

    expect(wrapper.getAllByRole('listitem')).toHaveLength(2)
  })

  it('supports option filtering', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: [
          ...testOptions,
          {
            value: 3,
            label: 'Ítem D',
          },
        ],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    let search = wrapper.getByRole('searchbox')

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(4)

    // Search is always case-insensitive.
    await wrapper.events.type(search, 'c')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item C')

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Search' }),
    )

    // Because of clicking outside the input is a toggle, we need to click twice
    await wrapper.events.click(wrapper.getByLabelText('Select'))
    await wrapper.events.click(wrapper.getByLabelText('Select'))

    search = wrapper.getByRole('searchbox')

    expect(search).toHaveValue('')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(4)

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(search, 'item d')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem D')

    await wrapper.events.clear(search)

    expect(search).toHaveValue('')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(4)

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(search, 'ítem d')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem D')
  })

  it('supports disabling filtering', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        noFiltering: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    expect(wrapper.queryByRole('searchbox')).not.toBeInTheDocument()
  })

  it('highlights matched text in filtered options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: [
          ...testOptions,
          {
            value: 3,
            label: 'Ítem D',
          },
        ],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'item')

    const selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption) => {
      if (selectOption.textContent === 'Ítem D') {
        expect(selectOption.children[1].children[0]).toHaveTextContent('Ítem')
      } else {
        expect(selectOption.children[1].children[0]).toHaveTextContent('Item')
      }

      expect(selectOption.children[1].children[0].children[0]).toHaveClasses([
        'bg-blue-600',
        'dark:bg-blue-900',
      ])
    })
  })
})

describe('Form - Field - Select - Features', () => {
  it('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'select',
        options: testOptions,
        clearable: false,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    const node = getNode('select')
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
        ...commonProps,
        type: 'select',
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
      },
    })

    const listitem = wrapper.getByRole('listitem')

    expect(listitem).toHaveTextContent(testOptions[1].label)

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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const menu = wrapper.getByRole('menu')

    let selectAllButton = getByRole(menu, 'button', {
      name: 'select all options',
    })

    const listbox = getByRole(menu, 'listbox')

    const selectOptions = getAllByRole(listbox, 'option')

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
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
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
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[2][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(selectAllButton).not.toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(0)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(3)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[3][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    await wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[4][0]).toStrictEqual([testOptions[0].value])
    })

    selectAllButton = getByRole(menu, 'button', {
      name: 'select all options',
    })

    expect(selectAllButton).toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(2)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(1)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(selectAllButton)

    await waitFor(() => {
      expect(emittedInput[5][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(selectAllButton).not.toBeInTheDocument()
    expect(queryAllByIconName(listbox, 'square')).toHaveLength(0)
    expect(queryAllByIconName(listbox, 'check-square')).toHaveLength(3)
    expect(wrapper.queryByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.rerender({
      sorting: 'value',
    })

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
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
        label: 'Item C',
      },
    ]

    i18n.setTranslationMap(new Map([['Item C', 'Translated Item C']]))

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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    listbox = wrapper.getByRole('listbox')

    selectOptions = getAllByRole(listbox, 'option')

    selectOptions.forEach((selectOption, index) => {
      // Forces translation due to placeholder availability.
      if (untranslatedOptions[index].labelPlaceholder) {
        expect(selectOption).toHaveTextContent(translatedOptions[index].label)
      } else {
        expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
      }
    })

    await wrapper.events.click(selectOptions[2])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[2].label,
    )
  })

  it('supports option pre-select', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        name: 'select',
        id: 'select',
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
    const node = getNode('select')
    node?.input(null)

    await wrapper.rerender({
      clearable: false,
      options: [
        {
          value: 2,
          label: 'Item C',
        },
      ],
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item C')

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
        name: 'select',
        id: 'select',
        options: disabledOptions,
      },
    })

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item B')
  })
})

describe('Form - Field - Select - Accessibility', () => {
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

    expect(wrapper.getByLabelText('Select')).toHaveAttribute('tabindex', '0')

    const listitem = wrapper.getByRole('listitem')

    expect(
      getByRole(listitem, 'button', { name: 'Unselect Option' }),
    ).toHaveAttribute('tabindex', '0')

    expect(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    ).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByLabelText('Select'))

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

  it('keeps focus on select', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    const selectField = wrapper.getByLabelText('Select')

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
        ...commonProps,
        type: 'select',
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select')).toHaveAttribute('tabindex', '0')
  })

  it('prevents opening of dropdown in disabled field', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: testOptions,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('shows a hint in case there are no options available', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select'))

    const listbox = wrapper.getByRole('listbox')

    const selectOptions = getAllByRole(listbox, 'option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveAttribute('aria-disabled', 'true')
    expect(selectOptions[0]).toHaveTextContent('No results found')
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
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Form - Field - Select - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...commonProps,
        id: 'test_id',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Select')).toHaveAttribute('id', 'test_id')
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

    expect(wrapper.getByLabelText('Select')).toHaveAttribute(
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

    wrapper.getByLabelText('Select').focus()
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

    await wrapper.events.click(wrapper.getByLabelText('Select'))

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

      expect(wrapper.getByRole('listitem')).toHaveTextContent(testOption.label)
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

    expect(wrapper.getByLabelText('Select')).toHaveClass(
      'formkit-disabled:pointer-events-none',
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

    expect(wrapper.getByLabelText('Select')).toHaveAttribute(
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

    expect(wrapper.getByTestId('field-select')).toHaveClass('formkit-input')
  })
})
