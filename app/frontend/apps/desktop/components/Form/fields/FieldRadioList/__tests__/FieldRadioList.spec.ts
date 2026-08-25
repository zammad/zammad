// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

// An option that owns a date field is answered by that date: it is the value of the *field*,
//   while the empty value of the option next to it says "no date at all".
const testOptionsWithDateField: SetRequired<RadioListOption, 'label'>[] = [
  {
    value: null,
    label: 'now',
  },
  {
    value: 'scheduled',
    label: 'Schedule for',
    dateField: {
      label: 'Date',
    },
  },
]

const wrapperParameters = {
  form: true,
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
      expect(selectOption).toHaveTextContent(testOptionsWithDescription[index].label)
    })
  })
})

describe('Form - Field - Radio List - option with a date field', () => {
  const DATE = '2021-04-13 11:10'
  const TIMESTAMP = '2021-04-13T11:10:00Z'

  const renderWithDateField = () => renderRadioListInput({ options: testOptionsWithDateField })

  const pickDate = async (view: Awaited<ReturnType<typeof renderRadioListInput>>) => {
    await view.events.type(view.getByLabelText('Date'), DATE)
    await view.events.keyboard('{Enter}')
  }

  it('renders the date field inside the group, below its own option', async () => {
    const view = await renderWithDateField()

    expect(
      view.queryByLabelText('Date'),
      'an option that is not picked has no date to offer',
    ).not.toBeInTheDocument()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))

    const dateField = await view.findByLabelText('Date')

    // One widget, not two fields: the picker is part of the group the option belongs to.
    expect(view.getByLabelText('Radio list')).toContainElement(dateField)

    // ... and outside the radio button itself, which would otherwise swallow every click meant
    //   for the picker.
    expect(view.getByRole('radio', { name: 'Schedule for' })).not.toContainElement(dateField)
  })

  // Picking the option is only half of the answer, so the field it asks for next takes the focus
  //   right away.
  it('focuses the date field when its own option is picked', async () => {
    const view = await renderWithDateField()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))

    await waitFor(() => {
      expect(view.getByLabelText('Date')).toHaveFocus()
    })
  })

  it('checks the option whose value is empty while the field has no value', async () => {
    const view = await renderWithDateField()

    expect(view.getByRole('radio', { name: 'now' })).toHaveAttribute('aria-checked', 'true')
    expect(view.getByRole('radio', { name: 'Schedule for' })).toHaveAttribute(
      'aria-checked',
      'false',
    )
  })

  it('commits the picked date as the value of the field', async () => {
    const view = await renderWithDateField()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))

    expect(
      getNode('radioList')?.value,
      'picking the option alone answers nothing - the date does',
    ).toBeNull()

    await pickDate(view)

    await waitFor(() => {
      expect(getNode('radioList')?.value).toBe(TIMESTAMP)
    })
  })

  it('checks the date option for a value none of the options owns', async () => {
    const view = await renderRadioListInput({
      options: testOptionsWithDateField,
      value: TIMESTAMP,
    })

    expect(view.getByRole('radio', { name: 'Schedule for' })).toHaveAttribute(
      'aria-checked',
      'true',
    )
    expect(view.getByRole('radio', { name: 'now' })).toHaveAttribute('aria-checked', 'false')
    expect(view.getByLabelText('Date')).toHaveDisplayValue(DATE)
  })

  it('keeps the date while its own option is picked again', async () => {
    const view = await renderWithDateField()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))
    await pickDate(view)

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))

    expect(view.getByLabelText('Date')).toHaveDisplayValue(DATE)
    expect(getNode('radioList')?.value).toBe(TIMESTAMP)
  })

  it('drops the date when another option is picked', async () => {
    const view = await renderWithDateField()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))
    await pickDate(view)

    await view.events.click(view.getByRole('radio', { name: 'now' }))

    expect(view.queryByLabelText('Date')).not.toBeInTheDocument()
    expect(getNode('radioList')?.value).toBeNull()
  })

  // Another session switching a scheduled draft back to immediate publication restores an empty
  //   value here, which has to move the selection back - unlike the empty value the field leaves
  //   behind itself while it waits for a date.
  it('follows an empty value it was handed back to the option that owns it', async () => {
    const view = await renderWithDateField()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))
    await pickDate(view)

    await waitFor(() => {
      expect(view.getByRole('radio', { name: 'Schedule for' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
    })

    getNode('radioList')?.input(null)

    await waitFor(() => {
      expect(view.getByRole('radio', { name: 'now' })).toHaveAttribute('aria-checked', 'true')
    })

    expect(view.getByRole('radio', { name: 'Schedule for' })).toHaveAttribute(
      'aria-checked',
      'false',
    )
  })

  // The picker is detached from the form (`ignore`), so a date it is missing could never block a
  //   submit by itself - the field the option belongs to has to report it, which it does with a
  //   blocking message of its own.
  it('reports a picked option that has no date yet', async () => {
    const view = await renderRadioListInput({
      options: testOptionsWithDateField,
      validationVisibility: 'live',
    })

    expect(
      view.queryByText('This field is required.'),
      'the empty option answers the field on its own',
    ).not.toBeInTheDocument()

    await view.events.click(view.getByRole('radio', { name: 'Schedule for' }))

    // Reported without a value being committed at all: what changed is only the selection.
    expect(await view.findByText('This field is required.')).toBeInTheDocument()

    await pickDate(view)

    await waitFor(() => {
      expect(view.queryByText('This field is required.')).not.toBeInTheDocument()
    })
  })
})

// A field may offer more than one date: each of them commits its own timestamp while it is the
//   picked option.
describe('Form - Field - Radio List - several options with a date field', () => {
  const optionsWithTwoDateFields: SetRequired<RadioListOption, 'label'>[] = [
    { value: null, label: 'now' },
    { value: 'first', label: 'First date', dateField: { label: 'Date A' } },
    { value: 'second', label: 'Second date', dateField: { label: 'Date B' } },
  ]

  const renderWithTwoDateFields = () => renderRadioListInput({ options: optionsWithTwoDateFields })

  it('keeps a picked date option that is not the first one', async () => {
    const view = await renderWithTwoDateFields()

    await view.events.click(view.getByRole('radio', { name: 'Second date' }))

    // Its own picker, and no other one - the option that is picked is the one that asks for a date.
    expect(await view.findByLabelText('Date B')).toBeInTheDocument()
    expect(view.queryByLabelText('Date A')).not.toBeInTheDocument()

    await view.events.type(view.getByLabelText('Date B'), '2021-04-13 11:10')
    await view.events.keyboard('{Enter}')

    await waitFor(() => {
      expect(getNode('radioList')?.value).toBe('2021-04-13T11:10:00Z')
    })

    expect(view.getByRole('radio', { name: 'Second date' })).toHaveAttribute('aria-checked', 'true')
  })

  // The tie-break the field cannot avoid: a stored timestamp carries no trace of the option it
  //   answered, so it goes to the first one that takes a date.
  it('gives a value none of the options owns to the first date option', async () => {
    const view = await renderRadioListInput({
      options: optionsWithTwoDateFields,
      value: '2021-04-13T11:10:00Z',
    })

    expect(view.getByRole('radio', { name: 'First date' })).toHaveAttribute('aria-checked', 'true')

    expect(view.getByRole('radio', { name: 'Second date' })).toHaveAttribute(
      'aria-checked',
      'false',
    )
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

    expect(view.getByLabelText('Radio list')).toHaveAttribute('name', 'test_name')
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

    expect(view.getByLabelText('Radio list')).toHaveAttribute('test-attribute', 'test_value')
  })

  it('implements standardized classes', async () => {
    const view = await renderRadioListInput()

    expect(view.getByLabelText('Radio list')).toHaveClass('formkit-input')
  })
})
