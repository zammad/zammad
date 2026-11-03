// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'

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

const day = (name: string) => ({ name: new RegExp(`^\\w+, ${name}, 2021$`) })

describe('Fields - FieldDate', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
    i18n.setTranslationMap(new Map())
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('type "date"', () => {
    it('opens the calendar below the field and commits a picked day', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')
      expect(input).toHaveAttribute('readonly')

      await view.events.click(input)

      expect(view.getByRole('dialog', { name: 'Choose date' })).toBeInTheDocument()
      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', day('April 12th')))

      expect(emittedValues(view)).toEqual(['2021-04-12'])
      expect(input).toHaveDisplayValue('2021-04-12')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('does not take typed input', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.type(input, '2021-04-12')

      expect(emittedValues(view)).toBeUndefined()
      expect(input).toHaveDisplayValue('')
    })

    it('picks today with the button', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13')
      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('closes the calendar on a click outside and with escape', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.click(input)

      expect(view.getByRole('dialog')).toBeInTheDocument()

      await view.events.click(document.body)

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()

      await view.events.click(input)
      await view.events.keyboard('{Escape}')

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('opens with the keyboard and moves through the days with the arrow keys', async () => {
      const view = await renderDateField({ value: '2021-04-12' })

      const input = view.getByLabelText('Date')

      input.focus()
      await view.events.keyboard('{Enter}')

      const dialog = view.getByRole('dialog', { name: 'Choose date' })

      expect(input).toHaveAttribute('aria-controls', dialog.id)
      expect(view.emitted().submit).toBeUndefined()

      await view.events.keyboard('{Escape}')

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(input).toHaveFocus()

      await view.events.keyboard('{Alt>}{ArrowDown}{/Alt}')
      await view.events.keyboard('{Escape}')
      await view.events.keyboard(' ')

      expect(view.getByRole('dialog')).toBeInTheDocument()

      const selected = view.getByRole('button', day('April 12th'))

      selected.focus()
      await view.events.keyboard('{ArrowRight}')

      expect(view.getByRole('button', day('April 13th'))).toHaveFocus()

      await view.events.keyboard('{ArrowDown}{Enter}')

      expect(emittedValues(view).at(-1)).toBe('2021-04-20')
    })

    it('navigates through the months, the years and the decades', async () => {
      const view = await renderDateField()

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', { name: 'Next month' }))

      expect(view.getByRole('grid', { name: 'May 2021' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Open the months overlay' }))

      expect(view.getByRole('grid', { name: 'The month picker' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Open the years overlay' }))

      expect(view.getByRole('grid', { name: 'The year picker' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: '2020 – 2029' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: '2023' }))
      await view.events.click(view.getByRole('button', { name: 'June 2023' }))
      await view.events.click(view.getByRole('button', { name: 'Friday, June 9th, 2023' }))

      expect(emittedValues(view)).toEqual(['2023-06-09'])
    })

    it('renders the initial value and clears it', async () => {
      const view = await renderDateField({ value: '2020-02-10', clearable: true })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('2020-02-10')

      await view.events.click(view.getByRole('button', { name: 'Clear the value' }))

      expect(emittedValues(view)).toEqual([null])
      expect(input).toHaveDisplayValue('')
    })

    it('keeps the focus in the field when clearing with the keyboard', async () => {
      const view = await renderDateField({ value: '2020-02-10', clearable: true })

      view.getByRole('button', { name: 'Clear the value' }).focus()
      await view.events.keyboard(' ')

      expect(view.getByLabelText('Date')).toHaveDisplayValue('')
      expect(view.getByLabelText('Date')).toHaveFocus()
    })

    it('does not open while disabled', async () => {
      const view = await renderDateField({ disabled: true })

      const input = view.getByLabelText('Date')

      expect(input).toBeDisabled()

      await view.events.click(input)

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('disables the days after today with pastOnly', async () => {
      const view = await renderDateField({ pastOnly: true })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 14th')))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', day('April 13th')))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
    })

    it('disables the days before today with futureOnly', async () => {
      const view = await renderDateField({ futureOnly: true })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 12th')))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', day('April 13th')))

      expect(emittedValues(view)).toEqual(['2021-04-13'])
    })

    it('follows a changed bound', async () => {
      const view = await renderDateField({ maxDate: '2021-04-14' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))

      expect(emittedValues(view)).toBeUndefined()

      await view.rerender({ maxDate: '2021-04-15' })
      await view.events.click(view.getByRole('button', day('April 15th')))

      expect(emittedValues(view)).toEqual(['2021-04-15'])
    })

    it('shows the calendar weeks when the setting asks for them', async () => {
      mockApplicationConfig({ datepicker_show_calendar_weeks: true })

      const view = await renderDateField()

      await view.events.click(view.getByLabelText('Date'))

      expect(view.getByRole('columnheader', { name: 'Calendar week' })).toBeInTheDocument()
      expect(view.getAllByRole('rowheader').map((week) => week.textContent?.trim())).toEqual([
        '13',
        '14',
        '15',
        '16',
        '17',
      ])
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
  })

  describe('type "datetime"', () => {
    it('defaults the time of a picked day to the morning and stays open until done', async () => {
      const view = await renderDateField({ type: 'datetime' })

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(view.getByRole('button', day('April 15th')))

      expect(emittedValues(view)).toEqual(['2021-04-15T08:00:00Z'])
      expect(input).toHaveDisplayValue('2021-04-15 08:00')
      expect(view.getByRole('dialog')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Open the hours overlay' })).toHaveTextContent('08')
      expect(view.getByRole('button', { name: 'Open the minutes overlay' })).toHaveTextContent('00')

      await view.events.click(view.getByRole('button', { name: 'Done' }))

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('steps the hours and the minutes by one', async () => {
      const view = await renderDateField({ type: 'datetime', value: '2021-04-15T08:00:00Z' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))
      await view.events.click(view.getByRole('button', { name: 'Increment hours value' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T09:00:00Z')

      await view.events.click(view.getByRole('button', { name: 'Decrement minutes value' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T09:59:00Z')
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-15 09:59')
    })

    it('picks the hours and the minutes from a grid', async () => {
      const view = await renderDateField({ type: 'datetime', value: '2021-04-15T08:00:00Z' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))
      await view.events.click(view.getByRole('button', { name: 'Open the hours overlay' }))

      const hours = view.getByRole('listbox', { name: 'The hours overlay' })

      expect(hours.querySelectorAll('[role="option"]')).toHaveLength(24)
      expect(view.getByRole('option', { name: '08' })).toHaveAttribute('aria-selected', 'true')
      expect(view.getByRole('button', { name: 'Back to the time picker' })).toHaveTextContent(
        '08:00',
      )

      await view.events.click(view.getByRole('option', { name: '14' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T14:00:00Z')
      expect(view.queryByRole('listbox')).not.toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Open the minutes overlay' }))

      expect(view.getByRole('listbox', { name: 'The minutes overlay' })).toBeInTheDocument()
      expect(view.getAllByRole('option')).toHaveLength(12)

      await view.events.click(view.getByRole('option', { name: '45' }))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T14:45:00Z')
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-15 14:45')
    })

    it('keeps the focus on the time value while a grid opens and closes', async () => {
      const view = await renderDateField({ type: 'datetime', value: '2021-04-15T16:00:00Z' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))

      const hours = view.getByRole('button', { name: 'Open the hours overlay' })

      hours.focus()
      await view.events.keyboard('{Enter}')

      expect(view.getByRole('option', { name: '16' })).toHaveFocus()

      await view.events.keyboard('{Enter}')

      expect(view.getByRole('button', { name: 'Open the hours overlay' })).toHaveFocus()

      await view.events.keyboard('{Escape}')

      expect(view.queryByRole('dialog')).not.toBeInTheDocument()
    })

    it('lands the focus on the nearest minute of the grid for a time off its raster', async () => {
      const view = await renderDateField({ type: 'datetime', value: '2021-04-15T16:07:00Z' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))

      view.getByRole('button', { name: 'Open the minutes overlay' }).focus()
      await view.events.keyboard('{Enter}')

      expect(view.getByRole('option', { name: '05' })).toHaveFocus()
      expect(view.queryByRole('option', { selected: true })).not.toBeInTheDocument()

      await view.events.keyboard('{Enter}')

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T16:05:00Z')
      expect(view.getByRole('button', { name: 'Open the minutes overlay' })).toHaveFocus()
    })

    it('returns from a grid to the time picker with its title', async () => {
      const view = await renderDateField({ type: 'datetime', value: '2021-04-15T08:00:00Z' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))
      await view.events.click(view.getByRole('button', { name: 'Open the minutes overlay' }))
      await view.events.click(view.getByRole('button', { name: 'Back to the time picker' }))

      expect(view.queryByRole('listbox')).not.toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Open the hours overlay' })).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Back to the calendar' }))

      expect(view.getByRole('grid', { name: 'April 2021' })).toBeInTheDocument()
    })

    it('picks today with the button', async () => {
      const view = await renderDateField({ type: 'datetime' })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(emittedValues(view)).toEqual(['2021-04-13T08:00:00Z'])
      expect(view.getByRole('button', { name: 'Done' })).toBeInTheDocument()
    })

    it('defaults the time to the morning again after clearing the value', async () => {
      const view = await renderDateField({
        type: 'datetime',
        value: '2021-04-12T14:30:00Z',
        clearable: true,
      })

      await view.events.click(view.getByRole('button', { name: 'Clear the value' }))
      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 15th')))

      expect(emittedValues(view).at(-1)).toBe('2021-04-15T08:00:00Z')
    })

    it('falls back to the current time when 08:00 today is already past, if futureOnly present', async () => {
      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 12th')))

      expect(emittedValues(view)).toBeUndefined()

      await view.events.click(view.getByRole('button', day('April 13th')))

      expect(emittedValues(view)).toEqual(['2021-04-13T11:10:00Z'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('falls back to the current time when 08:00 passed after mounting, if futureOnly present', async () => {
      vi.setSystemTime(new Date('2021-04-13T07:00:00Z'))

      const view = await renderDateField({ type: 'datetime', futureOnly: true })

      vi.setSystemTime(new Date('2021-04-13T09:00:00Z'))

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 13th')))

      expect(emittedValues(view)).toEqual(['2021-04-13T09:00:00Z'])
    })

    it('falls back to the current time when 08:00 today is still ahead, if pastOnly present', async () => {
      vi.setSystemTime(new Date('2021-04-13T06:30:00Z'))

      const view = await renderDateField({ type: 'datetime', pastOnly: true })

      await view.events.click(view.getByLabelText('Date'))
      await view.events.click(view.getByRole('button', day('April 13th')))

      expect(emittedValues(view)).toEqual(['2021-04-13T06:30:00Z'])
      expect(view.getByLabelText('Date')).toHaveDisplayValue('2021-04-13 06:30')
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

      await view.events.click(input)
      await view.events.click(view.getByRole('button', { name: 'Today' }))

      expect(input).toHaveDisplayValue('04/13/2021 08:00 am')

      await view.events.click(view.getByRole('button', { name: 'Toggle AM/PM mode' }))

      expect(input).toHaveDisplayValue('04/13/2021 08:00 pm')

      await view.events.click(view.getByRole('button', { name: 'Open the hours overlay' }))

      expect(view.getAllByRole('option')).toHaveLength(12)

      await view.events.click(view.getByRole('option', { name: '03' }))

      expect(input).toHaveDisplayValue('04/13/2021 03:00 pm')
    })
  })
})
