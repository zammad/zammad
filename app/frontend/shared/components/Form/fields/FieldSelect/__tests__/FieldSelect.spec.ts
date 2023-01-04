// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep, keyBy } from 'lodash-es'
import { getByText, waitFor } from '@testing-library/vue'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { i18n } from '@shared/i18n'
import { getNode } from '@formkit/core'
import { waitForNextTick } from '@tests/support/utils'

// Mock IntersectionObserver feature by injecting it into the global namespace.
//   More info here: https://vitest.dev/guide/mocking.html#globals
const IntersectionObserverMock = vi.fn(() => ({
  disconnect: vi.fn(),
  observe: vi.fn(),
  takeRecords: vi.fn(),
  unobserve: vi.fn(),
}))
vi.stubGlobal('IntersectionObserver', IntersectionObserverMock)

const testOptions = [
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
  dialog: true,
}

describe('Form - Field - Select - Dialog', () => {
  it('renders select options in a modal dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(wrapper.getByTestId('dialog-overlay'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        clearable: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

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
        type: 'select',
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(
      getByText(wrapper.getByRole('listbox'), testOptions[1].label),
    ).toHaveClass('font-semibold')

    expect(
      // TODO should work just with view.getByIconName('mobile-check') with Vitest 0.19
      wrapper.getByIconName((name, node) => {
        return (
          name === '#icon-mobile-check' &&
          !node?.parentElement?.classList.contains('invisible')
        )
      }),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByTestId('dialog-overlay'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })
})

describe('Form - Field - Select - Options', () => {
  it('supports unknown options', async () => {
    const optionsProp = cloneDeep(testOptions)

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        value: 3,
        options: optionsProp,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('3 (unknown)')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

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

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(optionsProp.length)

    await wrapper.events.click(wrapper.getByTestId('dialog-overlay'))

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
        clearable: true, // otherwise it defaults to the first option
        type: 'select',
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

    expect(emittedInput[0][0]).toBe(undefined)
    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
  })

  it('supports clearing of the existing multiple values when options goes away', async () => {
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
        type: 'select',
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
        type: 'select',
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getAllByRole('option')[1]).toHaveClass('pointer-events-none')

    expect(
      getByText(wrapper.getByRole('listbox'), disabledOptions[1].label),
    ).toHaveClass('opacity-30')
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
        type: 'select',
        options: statusOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

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
        icon: 'mobile-gitlab',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'mobile-github',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: iconOptions,
        clearable: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByIconName(iconOptions[0].icon)).toBeInTheDocument()
    expect(wrapper.queryByIconName(iconOptions[1].icon)).toBeInTheDocument()
  })

  it('supports historical options', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        value: 3,
        options: testOptions,
        historicalOptions: {
          ...keyBy(testOptions, 'value'),
          3: 'Item D',
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    selectOptions = wrapper.getAllByRole('option')

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
        type: 'select',
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

    expect(emittedInput[0][0]).toBe(undefined)
    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })
})

describe('Form - Field - Select - Features', () => {
  it('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        id: 'select',
        type: 'select',
        options: testOptions,
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

  it('can pass down a slot', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        value: testOptions[1].value,
      },
      slots: {
        output: '<span>Custom label</span>',
      },
    })

    expect(wrapper.getByText('Custom label')).toBeInTheDocument()
  })

  it('supports selection clearing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
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
        type: 'select',
        options: testOptions,
        multiple: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      wrapper.queryAllByIconName('mobile-check-box-no').length,
    )

    await wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])
    expect(wrapper.queryAllByIconName('mobile-check-box-no')).toHaveLength(2)
    expect(wrapper.queryAllByIconName('mobile-check-box-yes')).toHaveLength(1)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[1][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('mobile-check-box-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('mobile-check-box-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[2][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(wrapper.queryAllByIconName('mobile-check-box-no')).toHaveLength(0)
    expect(wrapper.queryAllByIconName('mobile-check-box-yes')).toHaveLength(3)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[3][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('mobile-check-box-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('mobile-check-box-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(wrapper.getByTestId('dialog-overlay'))
  })

  it('supports option sorting', async (context) => {
    context.skipConsole = true

    const reversedOptions = cloneDeep(testOptions).reverse()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: reversedOptions,
        sorting: 'label',
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

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
        type: 'select',
        options: untranslatedOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
    })

    await wrapper.events.click(selectOptions[1])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[1].label,
    )
  })

  it('supports option preselect', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
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

    await wrapper.events.click(wrapper.getByRole('button'))

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

    await wrapper.events.click(wrapper.getByRole('button'))

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
})

describe('Form - Field - Select - Accessibility', () => {
  it('supports element focusing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        clearable: true,
        value: testOptions[0].value,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')

    expect(wrapper.getByRole('button')).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption) => {
      expect(selectOption).toHaveAttribute('tabindex', '0')
    })
  })

  it('restores focus on close', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    const selectButton = wrapper.getByLabelText('Select…')

    await wrapper.events.click(selectButton)

    expect(selectButton).not.toHaveFocus()

    const selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.type(selectOptions[0], '{Space}')

    expect(selectButton).toHaveFocus()
  })

  it('prevents focusing of disabled field', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '-1')
  })

  it("clicking disabled field doesn't select dialog", async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it("clicking select without options doesn't open select dialog", async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('provides labels for screen readers', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute(
      'aria-label',
      'Select…',
    )

    expect(wrapper.getByRole('button')).toHaveAttribute(
      'aria-label',
      'Clear Selection',
    )
  })

  it('supports keyboard navigation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'select',
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.type(wrapper.getByLabelText('Select…'), '{Space}')

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
describe('Form - Field - Select - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        id: 'test_id',
        label: 'Test label',
        type: 'select',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('id', 'test_id')

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
        type: 'select',
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
        type: 'select',
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
        type: 'select',
        options: testOptions,
        clearable: true,
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
          type: 'select',
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
        type: 'select',
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
        type: 'select',
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
        type: 'select',
        options: testOptions,
      },
    })

    expect(wrapper.getByTestId('field-select')).toHaveClass('formkit-input')
  })
})
