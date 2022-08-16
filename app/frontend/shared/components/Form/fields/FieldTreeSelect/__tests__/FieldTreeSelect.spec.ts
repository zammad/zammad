// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import { getByText, waitFor } from '@testing-library/vue'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { i18n } from '@shared/i18n'

// Mock IntersectionObserver feature by injecting it into the global namespace.
//   More info here: https://vitest.dev/guide/mocking.html#globals
const IntersectionObserverMock = vi.fn(() => ({
  disconnect: vi.fn(),
  observe: vi.fn(),
  takeRecords: vi.fn(),
  unobserve: vi.fn(),
}))
vi.stubGlobal('IntersectionObserver', IntersectionObserverMock)

// FIXME: Vue Test Utils' teleport stub and HeadlessUI's Dialog don't work well together.
//   Temporarily disable `console.warn` method due to log being flooded with warnings such as:
//   [Vue warn]: Maximum recursive updates exceeded in component <Portal>. This means you have a reactive effect that is
//   mutating its own dependencies and thus recursively triggering itself. Possible sources include component template,
//   render function, updated hook or watcher source function.
//   More info here: https://github.com/tailwindlabs/headlessui/issues/1025
globalThis.console.warn = vi.fn() as never

const testOptions = [
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
  dialog: true,
}

beforeAll(async () => {
  // so we don't need to wait until it loads inside test
  await import('../FieldTreeSelectInputDialog.vue')
})

describe('Form - Field - TreeSelect - Dialog', () => {
  it('renders select options in a modal dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
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
        type: 'treeselect',
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(
      getByText(wrapper.getByRole('listbox'), testOptions[1].label),
    ).toHaveClass('font-semibold')

    expect(wrapper.getByIconName('check')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('shows full path of selected options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
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
        type: 'treeselect',
        options: testOptions,
      },
    })

    // Level 0
    await wrapper.events.click(wrapper.getByRole('list'))

    // only "Done"
    expect(wrapper.getAllByRole('button')).toHaveLength(1)

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    // Level 1
    await wrapper.events.click(wrapper.getAllByRole('link')[0])

    expect(wrapper.getAllByRole('button')[1]).toHaveTextContent(
      testOptions[0].label,
    )

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions[0].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label,
      )
    })

    // Level 2
    await wrapper.events.click(wrapper.getAllByRole('link')[0])

    expect(wrapper.getAllByRole('button')[1]).toHaveTextContent(
      testOptions[0].children![0].label,
    )

    expect(wrapper.getAllByRole('button')).toHaveLength(2)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      testOptions[0].children![0].children!.length,
    )

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![0].children![index].label,
      )
    })

    // Level 1
    await wrapper.events.click(wrapper.getAllByRole('button')[1])

    expect(wrapper.getAllByRole('button')[1]).toHaveTextContent(
      testOptions[0].label,
    )

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions[0].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label,
      )
    })

    // Level 2
    await wrapper.events.click(wrapper.getAllByRole('link')[1])

    expect(wrapper.getAllByRole('button')[1]).toHaveTextContent(
      testOptions[0].children![1].label,
    )

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      testOptions[0].children![1].children!.length,
    )

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![1].children![index].label,
      )
    })

    await wrapper.events.click(wrapper.getAllByRole('button')[0])

    // Level 0
    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getAllByRole('button')).toHaveLength(1)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })
})

describe('Form - Field - TreeSelect - Options', () => {
  it('supports options mutation', async () => {
    const optionsProp = cloneDeep(testOptions)

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
        value: 10,
        options: optionsProp,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('10')

    await wrapper.events.click(wrapper.getByRole('list'))

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    optionsProp.push({
      value: 10,
      label: 'Item D',
    })

    await wrapper.rerender({
      options: optionsProp,
    })

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')
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
            value: 2,
            label: 'Item 1',
          },
          {
            value: 2,
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
        type: 'treeselect',
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.getAllByRole('option')[1]).toHaveClass('pointer-events-none')

    expect(
      getByText(wrapper.getByRole('listbox'), disabledOptions[1].label),
    ).toHaveClass('opacity-30')

    await wrapper.events.click(wrapper.getByRole('link'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(disabledOptions[1].children!.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        disabledOptions[1].children![index].label,
      )
    })
  })

  it('supports status property', async () => {
    const statusOptions = [
      {
        value: 'open',
        label: 'Open',
        status: 'open',
      },
      {
        value: 'closed',
        label: 'Closed',
        status: 'closed',
      },
      {
        value: 'waiting-for-reminder',
        label: 'Waiting for closure',
        status: 'waiting-for-reminder',
      },
      {
        value: 'waiting-for-closure',
        label: 'Waiting for reminder',
        status: 'waiting-for-closure',
      },
      {
        value: 'escalated',
        label: 'Escalated',
        status: 'escalated',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
        options: statusOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const selectOptions = wrapper.getAllByRole('option')
    const selectedOptionStatuses = wrapper.getAllByRole('group')

    expect(selectOptions).toHaveLength(selectedOptionStatuses.length)

    await wrapper.events.click(selectOptions[0])

    expect(wrapper.getByRole('listitem')).toHaveAttribute(
      'data-test-status',
      statusOptions[0].status,
    )
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
        type: 'treeselect',
        options: iconOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    expect(wrapper.queryByIconName(iconOptions[0].icon)).toBeInTheDocument()
    expect(wrapper.queryByIconName(iconOptions[1].icon)).toBeInTheDocument()
  })
})

describe('Form - Field - TreeSelect - Features', () => {
  // FIXME: Updating value prop does not seem to mutate it.
  //   It could be a bug in FormKit, though. Retry with next release.
  it.todo('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
        options: untranslatedOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    let selectOptions = await wrapper.findAllByRole('option')

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

    await wrapper.events.click(wrapper.getByRole('list'))

    selectOptions = await wrapper.findAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
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
        type: 'treeselect',
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

  it('supports option filtering', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByRole('list'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    // Without parent filtering, search happens across all options, even nested ones.
    //   Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'iv')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)

    expect(selectOptions[0]).toHaveTextContent('Item IV — Item A — Item 2')

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'item c')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem C')

    await wrapper.events.clear(filterElement)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'ítem c')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Ítem C')

    await wrapper.events.clear(filterElement)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    await wrapper.events.click(wrapper.getAllByRole('link')[0])

    // With parent filtering, search happens only across children and other descendants.
    await wrapper.events.type(filterElement, 'a')

    selectOptions = wrapper.queryAllByRole('option')

    expect(selectOptions).toHaveLength(0)

    expect(wrapper.getByRole('alert')).toHaveTextContent('No results found')

    await wrapper.events.clear(filterElement)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label,
      )
      expect(selectOption).not.toHaveTextContent(`— ${testOptions[0].label}`)
    })

    // With parent filtering, search happens only across children and other descendants.
    await wrapper.events.type(filterElement, 'III')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item III — Item A — Item 1')

    await wrapper.rerender({ noFiltering: true })

    expect(filterElement).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptions[0].children![index].label,
      )
      expect(selectOption).not.toHaveTextContent(`— ${testOptions[0].label}`)
    })
  })
})

describe('Form - Field - TreeSelect - Accessibility', () => {
  it('supports element focusing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
describe('Form - Field - TreeSelect - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        id: 'test_id',
        label: 'Test label',
        type: 'treeselect',
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
        name: 'test_name',
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
          type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
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
        type: 'treeselect',
        options: testOptions,
      },
    })

    expect(wrapper.getByTestId('field-treeselect')).toHaveClass('formkit-input')
  })
})
