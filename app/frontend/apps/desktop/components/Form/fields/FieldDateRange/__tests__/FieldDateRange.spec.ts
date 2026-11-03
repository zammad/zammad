// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

const now = new Date('2021-04-13T11:10:00Z')

const renderDateRange = async (props: Record<string, unknown> = {}) => {
  return renderComponent(FormKit, {
    props: {
      type: 'daterange',
      name: 'range',
      label: 'Range',
      id: 'range',
      ...props,
    },
    form: true,
  })
}

type View = Awaited<ReturnType<typeof renderDateRange>>

const emittedValues = (view: View) =>
  (view.emitted().inputRaw as Array<Array<unknown>>)?.map((args) => args[0])

const openButtons = (view: View) =>
  view.getAllByRole('button', { name: /^(Choose date|Change date)/ })

const pickDay = async (view: View, side: 0 | 1, name: string) => {
  await view.events.click(openButtons(view)[side])
  await view.events.click(view.getByRole('button', { name }))
}

describe('Fields - FieldDateRange', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
    i18n.setTranslationMap(new Map())
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders a start and an end picker and commits a picked range', async () => {
    const view = await renderDateRange()

    const start = view.getByLabelText('Start date')
    const end = view.getByLabelText('End date')

    expect(start).toHaveDisplayValue('YYYY-MM-DD')
    expect(end).toHaveDisplayValue('YYYY-MM-DD')
    expect(view.getAllByIconName('calendar-event')).toHaveLength(2)
    expect(view.getByText('-', { selector: 'output > span' })).toBeInTheDocument()

    await pickDay(view, 0, 'Monday, April 12th, 2021')

    expect(emittedValues(view)).toEqual([['2021-04-12', null]])

    await pickDay(view, 1, 'Wednesday, April 14th, 2021')

    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12', '2021-04-14'])
    expect(start).toHaveDisplayValue('2021-04-12')
    expect(end).toHaveDisplayValue('2021-04-14')
  })

  it('commits only a complete range with partialRange disabled', async () => {
    const view = await renderDateRange({ partialRange: false })

    await pickDay(view, 0, 'Monday, April 12th, 2021')

    expect(emittedValues(view)).toBeUndefined()

    await pickDay(view, 1, 'Wednesday, April 14th, 2021')

    expect(emittedValues(view)).toEqual([['2021-04-12', '2021-04-14']])
  })

  it('empties the value when a bound of a committed range is cleared with partialRange disabled', async () => {
    const view = await renderDateRange({
      partialRange: false,
      clearable: true,
      value: ['2021-04-12', '2021-04-14'],
    })

    await view.events.click(view.getAllByRole('button', { name: 'Clear the value' })[0])

    expect(emittedValues(view)).toEqual([null])
    expect(view.getByLabelText('Start date')).toHaveDisplayValue('YYYY-MM-DD')
    expect(view.getByLabelText('End date')).toHaveDisplayValue('YYYY-MM-DD')
  })

  it('commits a typed range', async () => {
    const view = await renderDateRange()

    const selection = { initialSelectionStart: 0, initialSelectionEnd: 0 }

    await view.events.type(view.getByLabelText('Start date'), '2021-04-12', selection)
    await view.events.type(view.getByLabelText('End date'), '2021-04-14', selection)

    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12', '2021-04-14'])
  })

  it('refuses a typed end before the start and empties it when the field is left', async () => {
    const view = await renderDateRange({ value: ['2021-04-12', '2021-04-14'] })

    const selection = { initialSelectionStart: 0, initialSelectionEnd: 0 }

    await view.events.type(view.getByLabelText('End date'), '2021-04-10', selection)

    expect(emittedValues(view)).toBeUndefined()
    expect(view.getByLabelText('End date')).toHaveDisplayValue('2021-04-10')

    await view.events.click(document.body)

    expect(view.getByLabelText('End date')).toHaveDisplayValue('YYYY-MM-DD')
    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12', null])
  })

  it('heals a reversed range set from outside by swapping the bounds', async () => {
    const view = await renderDateRange({ value: ['2021-04-14', '2021-04-12'] })

    expect(view.getByLabelText('Start date')).toHaveDisplayValue('2021-04-12')
    expect(view.getByLabelText('End date')).toHaveDisplayValue('2021-04-14')
  })

  it('keeps each calendar within the other bound', async () => {
    const view = await renderDateRange({ value: ['2021-04-12', '2021-04-14'] })

    await view.events.click(openButtons(view)[1])

    expect(view.getByRole('button', { name: 'Sunday, April 11th, 2021' })).toHaveAttribute(
      'aria-disabled',
      'true',
    )
    expect(view.getByRole('button', { name: 'Monday, April 12th, 2021' })).not.toHaveAttribute(
      'aria-disabled',
    )

    await view.events.keyboard('{Escape}')
    await view.events.click(openButtons(view)[0])

    expect(view.getByRole('button', { name: 'Thursday, April 15th, 2021' })).toHaveAttribute(
      'aria-disabled',
      'true',
    )
  })

  it('keeps each calendar within the configured bound when the other value lies beyond it', async () => {
    const view = await renderDateRange({
      value: ['2021-04-08', '2021-04-20'],
      minDate: '2021-04-10',
      maxDate: '2021-04-16',
    })

    await view.events.click(openButtons(view)[0])

    expect(view.getByRole('button', { name: 'Saturday, April 17th, 2021' })).toHaveAttribute(
      'aria-disabled',
      'true',
    )

    await view.events.keyboard('{Escape}')
    await view.events.click(openButtons(view)[1])

    expect(view.getByRole('button', { name: 'Friday, April 9th, 2021' })).toHaveAttribute(
      'aria-disabled',
      'true',
    )
  })

  it('renders the initial value and clears it bound by bound', async () => {
    const view = await renderDateRange({ value: ['2021-04-12', '2021-04-14'], clearable: true })

    expect(view.getByLabelText('Start date')).toHaveDisplayValue('2021-04-12')
    expect(view.getByLabelText('End date')).toHaveDisplayValue('2021-04-14')

    const clearButtons = view.getAllByRole('button', { name: 'Clear the value' })

    await view.events.click(clearButtons[1])

    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12', null])

    await view.events.click(clearButtons[0])

    expect(emittedValues(view).at(-1)).toBeNull()
    expect(view.getByLabelText('Start date')).toHaveDisplayValue('YYYY-MM-DD')
  })

  it('commits timestamps covering the whole days of the bounds with a time panel', async () => {
    const view = await renderDateRange({ withTime: true })

    expect(view.getAllByIconName('calendar-date-time')).toHaveLength(2)

    await pickDay(view, 0, 'Monday, April 12th, 2021')
    await view.events.click(view.getByRole('button', { name: 'Done' }))
    await pickDay(view, 1, 'Wednesday, April 14th, 2021')

    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12T00:00:00Z', '2021-04-14T23:59:00Z'])
  })

  it('completes typed bounds without a time to the whole days', async () => {
    const view = await renderDateRange({ withTime: true })

    const selection = { initialSelectionStart: 0, initialSelectionEnd: 0 }

    await view.events.type(view.getByLabelText('Start date'), '20210412', selection)
    await view.events.type(view.getByLabelText('End date'), '20210414', selection)
    await view.events.click(document.body)

    expect(view.getByLabelText('Start date')).toHaveDisplayValue('2021-04-12 00:00')
    expect(view.getByLabelText('End date')).toHaveDisplayValue('2021-04-14 23:59')
    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12T00:00:00Z', '2021-04-14T23:59:00Z'])
  })

  it('completes typed bounds to the whole days on a 12-hour clock', async () => {
    i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

    const view = await renderDateRange({ withTime: true })

    const selection = { initialSelectionStart: 0, initialSelectionEnd: 0 }

    await view.events.type(view.getByLabelText('Start date'), '04122021', selection)
    await view.events.type(view.getByLabelText('End date'), '04142021', selection)
    await view.events.click(document.body)

    expect(view.getByLabelText('Start date')).toHaveDisplayValue('04/12/2021 12:00 am')
    expect(view.getByLabelText('End date')).toHaveDisplayValue('04/14/2021 11:59 pm')
    expect(emittedValues(view).at(-1)).toEqual(['2021-04-12T00:00:00Z', '2021-04-14T23:59:00Z'])
  })

  it('moves the focus from the label to the start picker', async () => {
    const view = await renderDateRange()

    await view.events.click(view.getByText('Range'))

    expect(view.getByLabelText('Start date')).toHaveFocus()
  })

  it('does not accept input while disabled', async () => {
    const view = await renderDateRange({ disabled: true })

    expect(view.getByLabelText('Start date')).toBeDisabled()
    expect(view.getByLabelText('End date')).toBeDisabled()
  })
})
