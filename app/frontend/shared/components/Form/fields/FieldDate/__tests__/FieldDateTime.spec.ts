// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable import/first */

const now = new Date('2021-04-13T11:10:10Z')
vi.useFakeTimers().setSystemTime(now)

import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'
import flatpickr from 'flatpickr'
import { i18n } from '@shared/i18n'
import { renderComponent } from '@tests/support/components'

const renderDateField = (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
  return renderComponent(FormKit, {
    props: {
      type: 'date',
      name: 'date',
      label: 'Date',
      id: 'date',
      ...props,
    },
    ...options,
    form: true,
  })
}

describe('Fields - FieldDate - type "date"', () => {
  beforeEach(() => {
    i18n.setTranslationMap(new Map())
  })

  beforeAll(() => {
    vi.useFakeTimers().setSystemTime(now)
  })

  afterAll(() => {
    vi.useRealTimers()
  })

  it('renders input and allows selecting date', async () => {
    const view = renderDateField()

    const input = view.getByLabelText('Date')

    expect(input).toBeInTheDocument()
    expect(input).toHaveDisplayValue('')

    const today = flatpickr.formatDate(now, 'Y-m-d')

    await view.events.click(view.getByLabelText(today))

    expect(input).toHaveDisplayValue(today)

    const changed = view.emitted().change[0] as [InputEvent]

    expect(changed[0].target).toBe(input)
  })

  it('respects locale', async () => {
    i18n.setTranslationMap(
      new Map([
        // label
        ['Date', 'Datum'],
        // friday
        ['Fri', 'Fre'],
        // current month
        [flatpickr.formatDate(now, 'F'), 'CurrentMonth'],
        // date format in input
        ['FORMAT_DATE', 'dd.mm.yyyy'],
      ]),
    )

    const view = renderDateField()

    const input = view.getByLabelText('Datum')

    expect(view.getByText('Fre')).toBeInTheDocument()
    expect(view.getByText('CurrentMonth')).toBeInTheDocument()

    const today = flatpickr.formatDate(now, 'd.m.Y')

    await view.events.click(view.getByLabelText(today))

    expect(input).toHaveDisplayValue(today)
  })

  it('sets the default date', () => {
    const view = renderDateField({
      value: '2020-02-10',
    })

    const input = view.getByLabelText('Date')

    expect(input).toHaveDisplayValue('2020-02-10')
  })

  const addDay = (date: Date, days: number) => {
    const cloned = new Date(date.getTime())
    const day = cloned.getDate()
    cloned.setDate(day + days)
    return cloned
  }

  it("can't select disabled dates", async () => {
    const yesterday = addDay(now, -1)
    const tomorrow = addDay(now, 1)

    const tomorrowString = flatpickr.formatDate(tomorrow, 'Y-m-d')
    const yesterdayString = flatpickr.formatDate(yesterday, 'Y-m-d')

    const view = renderDateField({
      maxDate: tomorrowString,
      minDate: yesterdayString,
    })

    const input = view.getByLabelText('Date')

    const tooEarlyDate = view.getByLabelText(
      flatpickr.formatDate(addDay(yesterday, -1), 'Y-m-d'),
    )
    const tooLateDate = view.getByLabelText(
      flatpickr.formatDate(addDay(tomorrow, 1), 'Y-m-d'),
    )

    await view.events.click(tooEarlyDate)

    expect(input).toHaveDisplayValue('')

    await view.events.click(tooLateDate)

    expect(input).toHaveDisplayValue('')

    const today = flatpickr.formatDate(now, 'Y-m-d')
    const todayDate = view.getByLabelText(today)

    await view.events.click(todayDate)

    expect(input).toHaveDisplayValue(today)
  })

  it('rerenders props', async () => {
    const tomorrow = addDay(now, 1)

    const tomorrowString = flatpickr.formatDate(tomorrow, 'Y-m-d')

    const view = renderDateField({
      maxDate: tomorrowString,
    })

    const input = view.getByLabelText('Date')

    const afterTomorrowString = flatpickr.formatDate(
      addDay(tomorrow, 1),
      'Y-m-d',
    )
    await view.events.click(view.getByLabelText(afterTomorrowString))

    expect(input).toHaveDisplayValue('')

    await view.rerender({
      maxDate: afterTomorrowString,
    })
    await view.events.click(view.getByLabelText(afterTomorrowString))

    expect(input).toHaveDisplayValue(afterTomorrowString)
  })

  it("doesn't allow changing anything while disabled", () => {
    const view = renderDateField({
      disabled: true,
    })

    const input = view.getByLabelText('Date')

    expect(input).toHaveAttribute('disabled')
    expect(
      view.queryByText(flatpickr.formatDate(now, 'F')),
      "doesn't render calendar",
    ).not.toBeInTheDocument()
  })

  it('disables days before today, if futureOnly present', () => {
    const view = renderDateField({
      futureOnly: true,
    })

    const today = flatpickr.formatDate(now, 'Y-m-d')
    const tomorrow = addDay(now, 1)
    const yesterday = addDay(now, -1)

    const tomorrowString = flatpickr.formatDate(tomorrow, 'Y-m-d')
    const yesterdayString = flatpickr.formatDate(yesterday, 'Y-m-d')

    expect(view.getByLabelText(today)).toHaveClass('flatpickr-disabled')
    expect(view.getByLabelText(yesterdayString)).toHaveClass(
      'flatpickr-disabled',
    )
    expect(view.getByLabelText(tomorrowString)).not.toHaveClass(
      'flatpickr-disabled',
    )
  })

  it('clears an input on clear button', async () => {
    const form = document.createElement('form')
    document.body.appendChild(form)
    const onSubmit = vi.fn((e: Event) => e.preventDefault())
    form.addEventListener('submit', onSubmit)

    const view = renderDateField(
      {
        value: '2020-02-10',
      },
      { baseElement: form },
    )

    const input = view.getByLabelText('Date')

    expect(input).toHaveDisplayValue('2020-02-10')

    await view.events.click(view.getByText('Clear'))

    expect(input).toHaveDisplayValue('')
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('selects today date on "today" button, if available', async () => {
    const form = document.createElement('form')
    document.body.appendChild(form)
    const onSubmit = vi.fn((e: Event) => e.preventDefault())
    form.addEventListener('submit', onSubmit)

    const view = renderDateField({}, { baseElement: form })

    const input = view.getByLabelText('Date')

    expect(input).toHaveDisplayValue('')

    const today = flatpickr.formatDate(now, 'Y-m-d')

    await view.events.click(view.getByText('Today'))

    expect(input).toHaveDisplayValue(today)
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('doesn\'t have "today" button, if it is disabled', async () => {
    const view = renderDateField({
      futureOnly: true,
    })

    expect(view.queryByText('Today')).not.toBeInTheDocument()
    const tomorrow = addDay(now, 1)

    const tomorrowString = flatpickr.formatDate(tomorrow, 'Y-m-d')

    await view.rerender({
      minDate: tomorrowString,
    })

    expect(view.queryByText('Today')).not.toBeInTheDocument()
  })
})

// Mocking date breaks flatpickr for some reason so, instead we relying
// on current date for the interaction tests.
describe('Fields - FieldDate - visuals', () => {
  beforeEach(() => {
    vi.stubGlobal('requestAnimationFrame', (cb: () => void) => cb())
  })

  it('calendar visibility changes based on interaction', async () => {
    const view = renderDateField()

    const calendar = view.getByRole('dialog')
    const input = view.getByLabelText('Date')

    await waitFor(() => {
      expect(calendar).toHaveAttribute('aria-hidden', 'true')
    })

    await view.events.click(input)

    expect(calendar).not.toHaveAttribute('aria-hidden')

    const today = flatpickr.formatDate(now, 'Y-m-d')
    await view.events.click(view.getByLabelText(today))

    expect(calendar).not.toHaveAttribute('aria-hidden')

    await view.events.click(view.getByText('Today'))

    expect(calendar).not.toHaveAttribute('aria-hidden')

    await view.events.click(document.body)

    expect(calendar).toHaveAttribute('aria-hidden', 'true')
  })

  it('prevents focussing of hidden buttons', async () => {
    const view = renderDateField()

    const calendar = view.getByRole('dialog')
    const input = view.getByLabelText('Date')

    await waitFor(() => {
      expect(calendar).toHaveAttribute('aria-hidden', 'true')
    })

    expect(view.getByText('Clear')).toHaveAttribute('tabindex', '-1')
    expect(view.getByText('Today')).toHaveAttribute('tabindex', '-1')

    await view.events.click(input)

    expect(calendar).not.toHaveAttribute('aria-hidden')
    expect(view.getByText('Clear')).not.toHaveAttribute('tabindex')
    expect(view.getByText('Today')).not.toHaveAttribute('tabindex')
  })
})

describe('Fields - FieldDate - type "datetime"', () => {
  beforeAll(() => {
    vi.useFakeTimers().setSystemTime(now)
  })

  afterAll(() => {
    vi.useRealTimers()
    i18n.setTranslationMap(new Map())
  })

  it('renders time inputs and allows to change it (24 hour)', async () => {
    const view = renderDateField({
      type: 'datetime',
    })

    const input = view.getByLabelText('Date')

    const hour = view.getByLabelText('Hour')
    const minutes = view.getByLabelText('Minute')

    expect(hour).toHaveDisplayValue('12')
    expect(minutes).toHaveDisplayValue('00')

    const today = flatpickr.formatDate(now, 'Y-m-d')
    await view.events.click(view.getByLabelText(`${today} 00:00`))

    expect(input).toHaveDisplayValue(`${today} 12:00`)

    await view.events.type(hour, '{backspace}{backspace}10')
    await view.events.type(minutes, '{backspace}{backspace}50')
    await view.events.click(document.body) // click away

    expect(input).toHaveDisplayValue(`${today} 10:50`)
  })

  it('renders AM/PM, if needed', async () => {
    i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

    const view = renderDateField({
      type: 'datetime',
    })

    const hour = view.getByLabelText('Hour')
    const minutes = view.getByLabelText('Minute')

    await view.events.type(hour, '{backspace}{backspace}10')
    await view.events.type(minutes, '{backspace}{backspace}50')
    await view.events.click(view.getByText('PM'))

    const input = view.getByLabelText('Date')

    const today = flatpickr.formatDate(now, 'm/d/Y')

    expect(input).toHaveDisplayValue(`${today} 10:50 am`)
  })
})
