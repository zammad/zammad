// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { RadioListOption } from '../types.ts'
import type { SetRequired } from 'type-fest'

const testOptions: SetRequired<RadioListOption, 'label'>[] = [
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

const testOptionsWithDescription: SetRequired<RadioListOption, 'label'>[] = [
  {
    value: 0,
    label: 'Item A',
    description: 'A Description',
  },
]

const wrapperParameters = {
  form: true,
  formField: true,
  dialog: true,
}

const renderRadioListInput = async (props: Record<string, unknown> = {}) => {
  const view = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      id: 'radioList',
      type: 'radioList',
      name: 'radioList',
      label: 'Radio list',
      formId: 'form',
      options: testOptions,
      ...props,
    },
    form: true,
  })

  await waitForNextTick(true)

  return view
}

describe('Form - Field - Radio List', () => {
  it('renders given options', async () => {
    const wrapper = await renderRadioListInput()

    const selectOptions = wrapper.getAllByRole('radio')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })

  it('shows optional description', async () => {
    const wrapper = await renderRadioListInput({
      options: testOptionsWithDescription,
    })

    const selectOptions = wrapper.getAllByRole('radio')

    expect(selectOptions).toHaveLength(testOptionsWithDescription.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(
        testOptionsWithDescription[index].label,
      )
    })
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Fields - Field Radio List - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderRadioListInput({
      id: 'test_id',
    })

    expect(view.getByLabelText('Radio list')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const view = await renderRadioListInput({
      name: 'test_name',
    })

    expect(view.getByLabelText('Radio list')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderRadioListInput({
      onBlur: blurHandler,
    })

    view.getByLabelText('Radio list').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = await renderRadioListInput()

    for await (const [i, item] of [testOptions[1], testOptions[2]].entries()) {
      wrapper.events.click(wrapper.getByRole('radio', { name: item.label }))

      await waitFor(() => {
        expect(wrapper.emitted().inputRaw[i]).toBeTruthy()
      })
    }

    await waitFor(() => {
      expect(getNode('radioList')?.value).toEqual(testOptions[2].value)
    })
  })

  it('implements input value display', async () => {
    const wrapper = await renderRadioListInput({
      value: [testOptions[1].value],
    })

    const radio1 = wrapper.getByRole('radio', { name: testOptions[0].label })
    expect(radio1).toHaveAttribute('aria-checked', 'false')

    const radio2 = wrapper.getByRole('radio', { name: testOptions[1].label })
    expect(radio2).toHaveAttribute('aria-checked', 'true')

    const radio3 = wrapper.getByRole('radio', { name: testOptions[2].label })
    expect(radio3).toHaveAttribute('aria-checked', 'false')
  })

  it('implements disabled', async () => {
    const view = await renderRadioListInput({
      disabled: true,
    })

    expect(view.getByLabelText('Radio list')).toBeDisabled()

    for (const option of testOptions) {
      expect(view.getByRole('radio', { name: option.label })).toBeDisabled()
    }
  })

  it('implements attribute passthrough', async () => {
    const view = await renderRadioListInput({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Radio list')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderRadioListInput()

    expect(view.getByLabelText('Radio list')).toHaveClass('formkit-input')
  })
})
