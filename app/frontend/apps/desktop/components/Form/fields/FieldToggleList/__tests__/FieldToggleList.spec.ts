// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { ToggleListOption } from '../types.ts'
import type { SetRequired } from 'type-fest'

const testOptions: SetRequired<ToggleListOption, 'label'>[] = [
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

const testOptionsWithDescription: SetRequired<ToggleListOption, 'label'>[] = [
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

const renderToggleListInput = async (props: Record<string, unknown> = {}) => {
  const view = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      id: 'toggleList',
      type: 'toggleList',
      name: 'toggleList',
      label: 'Toggle list',
      formId: 'form',
      options: testOptions,
      ...props,
    },
    form: true,
  })

  await waitForNextTick(true)

  return view
}

describe('Form - Field - Toggle List', () => {
  it('renders given options', async () => {
    const wrapper = await renderToggleListInput()

    const selectOptions = wrapper.getAllByRole('listitem')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })
  })

  it('shows optional description', async () => {
    const wrapper = await renderToggleListInput({
      options: testOptionsWithDescription,
    })

    const selectOptions = wrapper.getAllByRole('listitem')

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
describe('Fields - Field Toggle List - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderToggleListInput({
      id: 'test_id',
    })

    expect(view.getByLabelText('Toggle list')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const view = await renderToggleListInput({
      name: 'test_name',
    })

    expect(view.getByLabelText('Toggle list')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderToggleListInput({
      onBlur: blurHandler,
    })

    view.getByLabelText('Toggle list').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = await renderToggleListInput()

    for await (const [i, item] of [testOptions[1], testOptions[2]].entries()) {
      wrapper.events.click(wrapper.getByLabelText(item.label))

      await waitFor(() => {
        expect(wrapper.emitted().inputRaw[i]).toBeTruthy()
      })
    }

    await waitFor(() => {
      expect(getNode('toggleList')?.value).toEqual([
        testOptions[1].value,
        testOptions[2].value,
      ])
    })
  })

  it('implements input value display', async () => {
    const wrapper = await renderToggleListInput({
      value: [testOptions[1].value],
    })

    const toggle1 = wrapper.getByLabelText(testOptions[0].label)
    expect(toggle1).not.toBeChecked()

    const toggle2 = wrapper.getByLabelText(testOptions[1].label)
    expect(toggle2).toBeChecked()

    const toggle3 = wrapper.getByLabelText(testOptions[2].label)
    expect(toggle3).not.toBeChecked()
  })

  it('implements disabled', async () => {
    const view = await renderToggleListInput({
      disabled: true,
    })

    expect(view.getByLabelText('Toggle list')).toBeDisabled()

    for (const option of testOptions) {
      expect(view.getByLabelText(option.label)).toBeDisabled()
    }
  })

  it('implements attribute passthrough', async () => {
    const view = await renderToggleListInput({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Toggle list')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderToggleListInput()

    expect(view.getByLabelText('Toggle list')).toHaveClass('formkit-input')
  })
})
