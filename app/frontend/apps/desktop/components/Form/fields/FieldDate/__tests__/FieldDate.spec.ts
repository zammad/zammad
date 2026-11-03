// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { fireEvent } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { i18n } from '#shared/i18n.ts'

const now = new Date('2021-04-13T11:10:00Z')

const renderDateField = async (props: Record<string, unknown> = {}) => {
  return renderComponent(FormKit, {
    props: {
      type: 'date',
      name: 'date',
      label: 'Date',
      id: 'date',
      ...props,
    },
    form: true,
  })
}

const emittedValues = (view: Awaited<ReturnType<typeof renderDateField>>) =>
  (view.emitted().inputRaw as Array<Array<unknown>>)?.map((args) => args[0])

const caretAtStart = { initialSelectionStart: 0, initialSelectionEnd: 0 }

const openPanel = async (view: Awaited<ReturnType<typeof renderDateField>>) => {
  await view.events.click(view.getByRole('button', { name: /^(Choose|Change) date/ }))
}

// The announcer writes its message a moment after the call.
const announced = () => {
  vi.advanceTimersByTime(100)

  return document.getElementById('announcer-message')?.textContent
}

describe('Fields - FieldDate', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
    i18n.setTranslationMap(new Map())
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('type "date"', () => {
    it('shows the format and commits a picked day', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Monday, April 12th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-12'])
      expect(input).toHaveDisplayValue('2021-04-12')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('commits a typed date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.type(input, '2021-04-12', caretAtStart)

      expect(emittedValues(view)).toEqual(['2021-04-12'])
      expect(input).toHaveDisplayValue('2021-04-12')
    })

    it('picks today with the button', async () => {
      const view = await renderDateField()

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13')
    })

    it('renders the initial value and clears it', async () => {
      const view = await renderDateField({ value: '2020-02-10', clearable: true })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('2020-02-10')

      await view.events.click(view.getByRole('button', { name: 'Clear the value' }))

      expect(emittedValues(view)).toEqual([null])
      expect(input).toHaveDisplayValue('YYYY-MM-DD')
    })

    it('names the clear and the open button with a tooltip', async () => {
      const view = await renderDateField({ value: '2020-02-10', clearable: true })

      await view.events.hover(view.getByRole('button', { name: 'Clear the value' }))
      vi.advanceTimersByTime(1000)

      expect(view.getByRole('tooltip', { hidden: true })).toHaveTextContent('Clear the value')

      await view.events.hover(view.getByRole('button', { name: 'Change date, 2020-02-10' }))
      vi.advanceTimersByTime(1000)

      expect(view.getByRole('tooltip', { hidden: true })).toHaveTextContent(
        'Change date, 2020-02-10',
      )
    })

    it('offers no clear button while disabled', async () => {
      const view = await renderDateField({ value: '2020-02-10', clearable: true, disabled: true })

      expect(view.queryByRole('button', { name: 'Clear the value' })).not.toBeInTheDocument()
    })

    it('does not accept input or open the panel while disabled', async () => {
      const view = await renderDateField({ disabled: true })

      const input = view.getByLabelText('Date')

      expect(input).toBeDisabled()

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('disables the days after today with pastOnly', async () => {
      const view = await renderDateField({ pastOnly: true })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Wednesday, April 14th, 2021' }))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
    })

    it('disables the days before today with futureOnly', async () => {
      const view = await renderDateField({ futureOnly: true })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Monday, April 12th, 2021' }))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
    })

    it('refuses a typed date outside the bounds and empties it when the field is left', async () => {
      const view = await renderDateField({ futureOnly: true, value: '2021-04-20' })

      const input = view.getByLabelText('Date')

      await view.events.type(input, '2021-04-12', caretAtStart)

      expect(input).toHaveDisplayValue('2021-04-12')
      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('YYYY-MM-DD')
      expect(emittedValues(view)).toEqual([null])
      expect(announced()).toBe('The entry was not a valid date and has been cleared.')
    })

    it('follows a changed bound', async () => {
      const view = await renderDateField({ maxDate: '2021-04-14' })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.keyboard('{Escape}')
      await view.rerender({ maxDate: '2021-04-15' })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-15'])
    })

    it('reformats the field in place when the locale changes', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('2021-04-12')

      i18n.setTranslationMap(new Map([['FORMAT_DATE', 'dd.mm.yyyy']]))
      await waitForNextTick()

      expect(view.getByLabelText('Date')).toBe(input)
      expect(input).toHaveDisplayValue('12.04.2021')
      expect(emittedValues(view)).toBeUndefined()
    })

    it('is a spinbutton of the group being edited', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByRole('spinbutton', { name: 'Date Year' })

      expect(input).toHaveAttribute('aria-valuemin', '1')
      expect(input).toHaveAttribute('aria-valuemax', '9999')
      expect(input).toHaveAttribute('aria-valuenow', '2021')
      expect(input).toHaveAttribute('aria-valuetext', '2021')

      await view.events.pointer({ target: input, offset: 0, keys: '[MouseLeft]' })
      await view.events.keyboard('{ArrowRight}')

      expect(input).toHaveAccessibleName('Date Month')
      expect(input).toHaveAttribute('aria-valuemin', '1')
      expect(input).toHaveAttribute('aria-valuemax', '12')
      expect(input).toHaveAttribute('aria-valuenow', '4')
      expect(input).toHaveAttribute('aria-valuetext', '04')
      expect(announced()).toBe('Month, 04')

      await view.events.keyboard('{ArrowUp}')

      expect(input).toHaveAttribute('aria-valuenow', '5')
      expect(announced()).toBe('Month, 05')

      await view.events.keyboard('{Backspace}')

      expect(input).not.toHaveAttribute('aria-valuenow')
      expect(input).toHaveAttribute('aria-valuetext', 'not set')
      expect(announced()).toBe('Month, not set')

      await view.events.keyboard('0230')
      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('YYYY-MM-DD')
      expect(announced()).toBe('The entry was not a valid date and has been cleared.')
    })
  })

  describe('type "datetime"', () => {
    it('shows the format and commits a typed timestamp', async () => {
      const view = await renderDateField({ type: 'datetime' })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD hh:mm')

      await view.events.type(input, '2021-04-13 11:10', caretAtStart)

      expect(emittedValues(view)).toEqual(['2021-04-13T11:10:00Z'])
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('keeps the morning default on the day of a maximum without a time', async () => {
      const view = await renderDateField({ type: 'datetime', maxDate: '2021-04-15' })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-15T08:00:00Z'])
    })

    it('defaults the time of a picked day to the morning and goes on to the time panel', async () => {
      const view = await renderDateField({ type: 'datetime' })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-15T08:00:00Z'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-15 08:00')
      expect(view.getByLabelText('Hours')).toHaveValue(8)
    })

    it('picks today with the button', async () => {
      const view = await renderDateField({ type: 'datetime' })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T08:00:00Z'])
    })

    it('defaults an empty time to the morning when the field is left', async () => {
      const view = await renderDateField({ type: 'datetime' })

      const input = view.getByLabelText('Date')

      await view.events.type(input, '2021-04-15', caretAtStart)
      await view.events.click(document.body)

      expect(emittedValues(view)).toEqual(['2021-04-15T08:00:00Z'])
      expect(input).toHaveDisplayValue('2021-04-15 08:00')
    })

    it('falls back to the current time when 08:00 today is already past, if futureOnly present', async () => {
      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Monday, April 12th, 2021' }))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T11:10:00Z'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('falls back to the current time when 08:00 passed after mounting, if futureOnly present', async () => {
      vi.setSystemTime(new Date('2021-04-13T07:00:00Z'))

      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      vi.setSystemTime(new Date('2021-04-13T09:00:00Z'))

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T09:00:00Z'])
    })

    it('falls back to the current time when 08:00 today is still ahead, if pastOnly present', async () => {
      vi.setSystemTime(new Date('2021-04-13T06:30:00Z'))

      const view = await renderDateField({ type: 'datetime', pastOnly: true })

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T06:30:00Z'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13 06:30')
    })

    it('keeps a typed time of today inside the bounds, if futureOnly present', async () => {
      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      const input = view.getByLabelText('Date')

      await view.events.type(input, '2021-04-13 08:00', caretAtStart)

      expect(emittedValues(view)).toEqual(['2021-04-13T11:10:00Z'])
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
      expect(announced()).toBe('Minutes, 10')
    })

    it.each([
      {
        name: 'without milliseconds',
        value: '2024-07-08T11:00:00Z',
        display: '2024-07-08 11:00',
      },
      {
        name: 'with milliseconds',
        value: '2024-07-08T11:00:00.000Z',
        display: '2024-07-08 11:00',
      },
    ])('renders passed value - $name', async ({ value, display }) => {
      const view = await renderDateField({ type: 'datetime', value })

      expect(view.getByLabelText('Date')).toHaveDisplayValue(display)
    })

    it('renders AM/PM, if needed', async () => {
      i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

      const view = await renderDateField({ type: 'datetime' })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('MM/DD/YYYY hh:mm pp')

      await openPanel(view)
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(input).toHaveDisplayValue('04/13/2021 08:00 am')
    })
  })

  describe('text input', () => {
    it('shows the format as overlay and commits a typed date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.events.type(input, '2021-04-12', {
        initialSelectionStart: 0,
        initialSelectionEnd: 0,
      })

      expect(emittedValues(view)).toEqual(['2021-04-12'])
      expect(input).toHaveDisplayValue('2021-04-12')
    })

    it('mutes the groups without a value', async () => {
      const view = await renderDateField()

      const groups = () =>
        Array.from(view.container.querySelectorAll('[data-test-id="field-date-groups"] span')).map(
          (group) => [group.textContent, group.classList.contains('text-stone-200')],
        )

      expect(groups()).toEqual([
        ['YYYY', true],
        ['-', true],
        ['MM', true],
        ['-', true],
        ['DD', true],
      ])

      await view.events.type(view.getByLabelText('Date'), '202104', {
        initialSelectionStart: 0,
        initialSelectionEnd: 0,
      })

      expect(groups()).toEqual([
        ['2021', false],
        ['-', false],
        ['04', false],
        ['-', true],
        ['DD', true],
      ])
    })
  })

  describe('groups', () => {
    const selection = (input: HTMLElement) => [
      (input as HTMLInputElement).selectionStart,
      (input as HTMLInputElement).selectionEnd,
    ]

    it('selects the group under the caret and moves between groups with the arrow keys', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 9, keys: '[MouseLeft]' })

      expect(selection(input)).toEqual([8, 10])

      await view.events.keyboard('{ArrowLeft}')

      expect(selection(input)).toEqual([5, 7])

      await view.events.keyboard('{ArrowLeft}')

      expect(selection(input)).toEqual([0, 4])

      await view.events.keyboard('{End}')

      expect(selection(input)).toEqual([8, 10])
    })

    it('keeps a stretch selected by hand, so it can be copied', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer([
        { target: input, offset: 0, keys: '[MouseLeft>]' },
        { offset: 10 },
        { keys: '[/MouseLeft]' },
      ])

      expect(selection(input)).toEqual([0, 10])
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })

      expect(selection(input)).toEqual([5, 7])
    })

    it('selects the first group when focused with the keyboard', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      await view.events.tab()

      expect(selection(view.getByLabelText('Date'))).toEqual([0, 4])
    })

    it('edits one group at a time and moves on once it is complete', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('7')

      expect(input).toHaveDisplayValue('2021-07-12')
      expect(emittedValues(view).at(-1)).toBe('2021-07-12')
      expect(selection(input)).toEqual([8, 10])

      await view.events.keyboard('31')

      expect(input).toHaveDisplayValue('2021-07-31')
      expect(emittedValues(view).at(-1)).toBe('2021-07-31')

      await view.events.keyboard('{Home}1999')

      expect(input).toHaveDisplayValue('1999-07-31')
      expect(emittedValues(view).at(-1)).toBe('1999-07-31')
      expect(selection(input)).toEqual([5, 7])
    })

    it('waits for a second digit while the group allows one', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('1')

      expect(input).toHaveDisplayValue('2021-01-12')
      expect(selection(input)).toEqual([5, 7])
      expect(emittedValues(view)).toBeUndefined()

      await view.events.keyboard('2')

      expect(input).toHaveDisplayValue('2021-12-12')
      expect(selection(input)).toEqual([8, 10])
      expect(emittedValues(view)).toEqual(['2021-12-12'])
    })

    it('empties the field when it is left with a partial date', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('{Backspace}')

      expect(input).toHaveDisplayValue('2021-MM-12')

      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('YYYY-MM-DD')
      expect(emittedValues(view)).toEqual([null])
    })

    it('empties the field when it is left with an impossible date', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('0230')

      expect(emittedValues(view).at(-1)).toBe('2021-02-12')

      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('YYYY-MM-DD')
      expect(emittedValues(view).at(-1)).toBeNull()
    })

    it('completes a short year with the century when its group is left', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 1, keys: '[MouseLeft]' })
      await view.events.keyboard('99{ArrowRight}')

      expect(input).toHaveDisplayValue('1999-04-12')
      expect(emittedValues(view).at(-1)).toBe('1999-04-12')

      await view.events.keyboard('{Home}5{Tab}')

      expect(input).toHaveDisplayValue('2005-04-12')
      expect(emittedValues(view).at(-1)).toBe('2005-04-12')

      await view.events.keyboard('{Home}70-')

      expect(input).toHaveDisplayValue('2070-04-12')
      expect(emittedValues(view).at(-1)).toBe('2070-04-12')

      await view.events.keyboard('{Home}71')
      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('1971-04-12')
      expect(emittedValues(view).at(-1)).toBe('1971-04-12')
    })

    it('completes a short year ahead of now with futureOnly', async () => {
      const view = await renderDateField({ value: '2021-04-12', futureOnly: true })
      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 1, keys: '[MouseLeft]' })
      await view.events.keyboard('20{ArrowRight}')

      expect(input).toHaveDisplayValue('2120-04-12')
    })

    it('completes a short year behind now with pastOnly', async () => {
      const view = await renderDateField({ value: '2021-04-12', pastOnly: true })
      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 1, keys: '[MouseLeft]' })
      await view.events.keyboard('22{ArrowRight}')

      expect(input).toHaveDisplayValue('1922-04-12')
    })

    it('applies a half-typed group when the field is left', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('1')

      expect(emittedValues(view)).toBeUndefined()

      await view.events.tab()

      expect(emittedValues(view)).toEqual(['2021-01-12'])
    })

    it('keeps the current value until an impossible date is corrected', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('0230')

      expect(input).toHaveDisplayValue('2021-02-30')
      expect(emittedValues(view).at(-1)).toBe('2021-02-12')

      await view.events.keyboard('28')

      expect(input).toHaveDisplayValue('2021-02-28')
      expect(emittedValues(view).at(-1)).toBe('2021-02-28')
    })

    it('steps a group with the up and down keys', async () => {
      const view = await renderDateField({ value: '2021-12-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('{ArrowUp}')

      expect(input).toHaveDisplayValue('2021-01-12')
      expect(emittedValues(view).at(-1)).toBe('2021-01-12')

      await view.events.keyboard('{ArrowDown}{ArrowDown}')

      expect(input).toHaveDisplayValue('2021-11-12')
      expect(selection(input)).toEqual([5, 7])
    })

    it('steps an empty year from the current one', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.tab()
      await view.events.keyboard('{ArrowUp}')

      expect(input).toHaveDisplayValue('2021-MM-DD')

      await view.events.keyboard('{Backspace}{ArrowDown}')

      expect(input).toHaveDisplayValue('2021-MM-DD')
    })

    it('clears one group with backspace and the value once every group is empty', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.pointer({ target: input, offset: 6, keys: '[MouseLeft]' })
      await view.events.keyboard('{Backspace}')

      expect(input).toHaveDisplayValue('2021-MM-12')
      expect(emittedValues(view)).toBeUndefined()

      await view.events.keyboard('{ArrowLeft}{Backspace}{End}{Delete}')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')
      expect(emittedValues(view)).toEqual([null])
    })

    it('spreads pasted input over the groups', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.paste('2021-04-12')

      expect(input).toHaveDisplayValue('2021-04-12')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12')

      await view.events.paste('5/6/2022')

      expect(input).toHaveDisplayValue('2005-06-2022')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12')

      await view.events.paste('2022-06-05T10:00:00Z')

      expect(input).toHaveDisplayValue('2022-06-05')
      expect(emittedValues(view).at(-1)).toBe('2022-06-05')
    })

    it('completes a pasted short year like a typed one', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.paste('22-06-05')

      expect(input).toHaveDisplayValue('2022-06-05')
      expect(emittedValues(view).at(-1)).toBe('2022-06-05')

      await view.events.paste('21/4/12')

      expect(input).toHaveDisplayValue('2021-04-12')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12')
    })

    it('moves through the groups with tab and leaves the field after the last one', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      await view.events.tab()

      expect(selection(input)).toEqual([0, 4])

      await view.events.tab()

      expect(selection(input)).toEqual([5, 7])

      await view.events.tab()
      await view.events.tab()

      expect(input).not.toHaveFocus()

      await view.events.tab({ shift: true })

      expect(input).toHaveFocus()
      expect(selection(input)).toEqual([8, 10])
    })

    it('edits the time groups of a 12-hour clock', async () => {
      i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

      const view = await renderDateField({
        type: 'datetime',
        value: '2021-04-12T09:30:00Z',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('04/12/2021 09:30 am')

      await view.events.pointer({ target: input, offset: 12, keys: '[MouseLeft]' })
      await view.events.keyboard('7')

      expect(input).toHaveDisplayValue('04/12/2021 07:30 am')
      expect(selection(input)).toEqual([14, 16])

      await view.events.keyboard('05p')

      expect(input).toHaveDisplayValue('04/12/2021 07:05 pm')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12T19:05:00Z')

      await view.events.keyboard('{ArrowUp}')

      expect(input).toHaveDisplayValue('04/12/2021 07:05 am')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12T07:05:00Z')

      await view.events.keyboard('{ArrowLeft}{Backspace}{ArrowLeft}9')
      await view.events.click(document.body)

      expect(input).toHaveDisplayValue('04/12/2021 09:00 am')
      expect(emittedValues(view).at(-1)).toBe('2021-04-12T09:00:00Z')
    })
  })

  describe('panel', () => {
    it('opens with the button, commits a picked day and closes', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      const dialog = view.getByRole('dialog', { name: 'Choose date' })

      expect(dialog).toBeInTheDocument()
      expect(dialog).toHaveClass('min-w-68')
      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()
      expect(view.getAllByRole('columnheader')[0]).toHaveTextContent('Mo')

      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-15'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-15')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Change date, 2021-04-15' })).toBeInTheDocument()
    })

    it('is operated with the keyboard', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.keyboard('{Alt>}{ArrowDown}{/Alt}')
      await waitForNextTick()

      expect(view.getByRole('dialog')).toBeInTheDocument()
      expect(document.activeElement).toHaveAccessibleName('Tuesday, April 13th, 2021')

      await view.events.keyboard('{ArrowRight}')
      await waitForNextTick()

      expect(document.activeElement).toHaveAccessibleName('Wednesday, April 14th, 2021')
      expect(document.activeElement).toHaveClass('outline-blue-800')

      await view.events.keyboard('{ArrowDown}')
      await waitForNextTick()

      expect(document.activeElement).toHaveAccessibleName('Wednesday, April 21st, 2021')

      await view.events.tab()

      expect(document.activeElement).toHaveAccessibleName('Today')

      await view.events.tab({ shift: true })

      expect(document.activeElement).toHaveAccessibleName('Wednesday, April 21st, 2021')

      await view.events.keyboard('{Enter}')

      expect(emittedValues(view)).toEqual(['2021-04-21'])
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('navigates with the header into other months, years and decades', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))
      await view.events.click(view.getByRole('button', { name: 'Next month' }))

      expect(view.getByRole('grid', { name: 'May 2021' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Open the months overlay' }))

      expect(view.getByRole('grid', { name: 'The month picker' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Open the years overlay' }))

      expect(view.getByRole('grid', { name: 'The year picker' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: '2020 – 2029' })).toBeDisabled()

      await view.events.click(view.getByRole('button', { name: 'Next decade' }))
      await view.events.click(view.getByRole('button', { name: '2033' }))
      await view.events.click(view.getByRole('button', { name: 'February 2033' }))

      expect(view.getByRole('grid', { name: 'February 2033' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Monday, February 14th, 2033' }))

      expect(emittedValues(view)).toEqual(['2033-02-14'])
    })

    it('honors the week start', async () => {
      const view = await renderDateField({ weekStart: 0 })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()
      expect(view.getAllByRole('columnheader')[0]).toHaveTextContent('Su')
    })

    it('picks today with the button and closes', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))
      await view.events.click(view.getByRole('button', { name: 'Open the months overlay' }))
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(view.getByLabelText('Date')).toHaveFocus()
    })

    it('picks today with the button and continues to the time panel', async () => {
      const view = await renderDateField({ type: 'datetime' })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T08:00:00Z'])
      expect(view.getByLabelText('Hours')).toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Today' })).not.toBeInTheDocument()
    })

    it('disables the today button when today is out of bounds', async () => {
      const view = await renderDateField({ minDate: '2021-04-14' })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.getByRole('button', { name: 'Today' })).toBeDisabled()
    })

    it('shows the calendar weeks when the setting asks for them', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.queryByRole('columnheader', { name: 'Calendar week' })).not.toBeInTheDocument()

      await view.events.keyboard('{Escape}')

      mockApplicationConfig({ datepicker_show_calendar_weeks: true })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.getByRole('columnheader', { name: 'Calendar week' })).toBeInTheDocument()

      const weeks = Array.from(
        view.container.ownerDocument.querySelectorAll('[data-test-id="field-date-week"]'),
      ).map((week) => week.textContent?.trim())

      expect(weeks).toEqual(['13', '14', '15', '16', '17'])
      expect(view.getAllByRole('rowheader')[0]).toHaveClass('cursor-default', 'font-bold')
    })

    it('starts at the first group with the panel alongside on a click behind the groups', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date') as HTMLInputElement
      const groups = view.container.querySelector('[data-test-id="field-date-groups"]')!

      vi.spyOn(groups, 'getBoundingClientRect').mockReturnValue({
        width: 80,
        right: 90,
      } as DOMRect)

      input.focus()
      input.setSelectionRange(0, 0)
      await fireEvent.click(input, { clientX: 60 })

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()

      input.setSelectionRange(0, 0)
      await fireEvent.click(input, { clientX: 200 })
      await waitForNextTick()

      expect(view.getByRole('dialog', { name: 'Choose date' })).toBeInTheDocument()
      expect(input).toHaveFocus()
      expect([input.selectionStart, input.selectionEnd]).toEqual([0, 4])

      await view.events.keyboard('20210412')

      expect(emittedValues(view)).toEqual(['2021-04-12'])
      expect(
        view.container.ownerDocument.querySelector('td[aria-selected="true"]'),
      ).toHaveTextContent('12')

      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('follows the edited group between the calendar and the time panel', async () => {
      const view = await renderDateField({
        type: 'datetime',
        value: '2021-04-12T09:30:00Z',
      })

      const input = view.getByLabelText('Date') as HTMLInputElement
      const groups = view.container.querySelector('[data-test-id="field-date-groups"]')!

      vi.spyOn(groups, 'getBoundingClientRect').mockReturnValue({
        width: 80,
        right: 90,
      } as DOMRect)

      input.focus()
      input.setSelectionRange(0, 0)
      await fireEvent.click(input, { clientX: 200 })
      await waitForNextTick()

      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()

      await view.events.keyboard('{End}')

      expect(view.getByLabelText('Hours')).toBeInTheDocument()
      expect(input).toHaveFocus()

      await view.events.keyboard('{Home}')

      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('closes the panel shown alongside once the focus leaves the field', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')
      const groups = view.container.querySelector('[data-test-id="field-date-groups"]')!

      vi.spyOn(groups, 'getBoundingClientRect').mockReturnValue({
        width: 80,
        right: 90,
      } as DOMRect)

      input.focus()
      ;(input as HTMLInputElement).setSelectionRange(0, 0)
      await fireEvent.click(input, { clientX: 200 })
      await waitForNextTick()

      expect(view.getByRole('dialog')).toBeInTheDocument()

      await view.events.tab()
      await view.events.tab()
      await view.events.tab()

      expect(view.getByRole('button', { name: 'Choose date' })).toHaveFocus()
      expect(view.getByRole('dialog')).toBeInTheDocument()

      const outside = document.createElement('button')
      document.body.append(outside)
      outside.focus()
      await waitForNextTick()

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()

      outside.remove()
    })

    it('keeps a single cell of each grid in the tab order', async () => {
      const view = await renderDateField()

      await openPanel(view)

      const tabStops = () =>
        view.getByRole('dialog').querySelectorAll('[role="grid"] button[tabindex="0"]')

      expect(tabStops()).toHaveLength(1)
      expect(tabStops()[0]).toHaveAccessibleName('Tuesday, April 13th, 2021')

      await view.events.click(view.getByRole('button', { name: 'Open the months overlay' }))

      expect(tabStops()).toHaveLength(1)
      expect(tabStops()[0]).toHaveAccessibleName('April 2021')

      await view.events.click(view.getByRole('button', { name: 'Open the years overlay' }))

      expect(tabStops()).toHaveLength(1)
      expect(tabStops()[0]).toHaveTextContent('2021')
    })

    it('is modal only when it takes the focus', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date') as HTMLInputElement
      const groups = view.container.querySelector('[data-test-id="field-date-groups"]')!

      vi.spyOn(groups, 'getBoundingClientRect').mockReturnValue({
        width: 80,
        right: 90,
      } as DOMRect)

      await openPanel(view)

      expect(view.getByRole('dialog')).toHaveAttribute('aria-modal', 'true')

      await view.events.keyboard('{Escape}')

      input.focus()
      input.setSelectionRange(0, 0)
      await fireEvent.click(input, { clientX: 200 })
      await waitForNextTick()

      expect(view.getByRole('dialog')).not.toHaveAttribute('aria-modal')
      expect(input).toHaveFocus()
    })

    it('does not open while disabled', async () => {
      const view = await renderDateField({ disabled: true })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })
  })

  describe('bounds', () => {
    it('disables days after today, if pastOnly present', async () => {
      const view = await renderDateField({ pastOnly: true })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      const tomorrow = view.getByRole('button', { name: 'Wednesday, April 14th, 2021' })

      expect(tomorrow).toHaveAttribute('aria-disabled', 'true')
      expect(tomorrow).toHaveAttribute('tabindex', '-1')
      expect(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' })).toHaveAttribute(
        'tabindex',
        '0',
      )

      await view.events.click(tomorrow)

      expect(emittedValues(view)).toBeUndefined()
      expect(view.getByRole('dialog')).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
    })

    it('keeps the keyboard cursor off disabled days', async () => {
      const view = await renderDateField({ pastOnly: true })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.keyboard('{Alt>}{ArrowDown}{/Alt}')
      await waitForNextTick()

      expect(document.activeElement).toHaveAccessibleName('Tuesday, April 13th, 2021')

      await view.events.keyboard('{ArrowRight}')
      await waitForNextTick()

      expect(document.activeElement).toHaveAccessibleName('Tuesday, April 13th, 2021')

      await view.events.keyboard('{ArrowLeft}')
      await waitForNextTick()

      expect(document.activeElement).toHaveAccessibleName('Monday, April 12th, 2021')
    })

    it('disables days refused by the callback', async () => {
      const view = await renderDateField({
        disabledDays: (date: Date) => date.getDate() === 15,
      })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))

      expect(view.getByRole('button', { name: 'Thursday, April 15th, 2021' })).toHaveAttribute(
        'aria-disabled',
        'true',
      )
      expect(view.getByRole('button', { name: 'Friday, April 16th, 2021' })).not.toHaveAttribute(
        'aria-disabled',
      )
    })
  })

  describe('time panel', () => {
    it('defaults a picked date to the morning and adjusts the time', async () => {
      const view = await renderDateField({ type: 'datetime' })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD hh:mm')

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-15T08:00:00Z'])
      expect(input).toHaveDisplayValue('2021-04-15 08:00')
      expect(view.getByRole('dialog')).toBeInTheDocument()

      const hours = view.getByLabelText('Hours')

      expect(hours).toHaveValue(8)
      expect(view.getByLabelText('Minutes')).toHaveValue(0)

      await waitForNextTick()

      expect(hours).toHaveFocus()

      await view.events.clear(hours)
      await view.events.type(hours, '17')

      const minutes = view.getByLabelText('Minutes')

      await view.events.clear(minutes)

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T17:00:00Z')
      expect(hours).toHaveValue(17)

      await view.events.type(minutes, '45{Enter}')

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T17:45:00Z')
      expect(input).toHaveDisplayValue('2021-04-15 17:45')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('refuses an impossible time and keeps the applied one', async () => {
      const view = await renderDateField({
        type: 'datetime',
        value: '2021-04-10T15:30:00Z',
      })

      await view.events.click(view.getByRole('button', { name: 'Change date, 2021-04-10 15:30' }))
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      const hours = view.getByLabelText('Hours')

      await view.events.clear(hours)
      await view.events.type(hours, '99')
      await view.events.click(view.getByRole('button', { name: 'Done' }))

      expect(hours).toHaveValue(15)
      expect(emittedValues(view).at(-1)).toBe('2021-04-15T15:30:00Z')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('keeps the half of the day when an hour is entered on a 12-hour clock', async () => {
      i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

      const view = await renderDateField({ type: 'datetime', value: '2021-04-10T15:30:00Z' })

      await view.events.click(
        view.getByRole('button', { name: 'Change date, 04/10/2021 03:30 pm' }),
      )
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      const hours = view.getByLabelText('Hours')

      await view.events.clear(hours)
      await view.events.type(hours, '12')
      await view.events.click(view.getByRole('button', { name: 'Done' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T12:30:00Z')
      expect(view.getByLabelText('Date')).toHaveDisplayValue('04/15/2021 12:30 pm')
    })

    it('falls back to the current time when the morning is already past, if futureOnly present', async () => {
      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      await view.events.click(view.getByRole('button', { name: 'Choose date' }))
      await view.events.click(view.getByRole('button', { name: 'Tuesday, April 13th, 2021' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T11:10:00Z'])
    })

    it('keeps the time of the current value when picking another day', async () => {
      const view = await renderDateField({
        type: 'datetime',
        value: '2021-04-10T15:30:00Z',
      })

      await view.events.click(view.getByRole('button', { name: 'Change date, 2021-04-10 15:30' }))
      await view.events.click(view.getByRole('button', { name: 'Thursday, April 15th, 2021' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T15:30:00Z')
    })
  })
})
