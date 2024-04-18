// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const { FormKit } = await import('@formkit/vue')
const { renderComponent } = await import('#tests/support/components/index.ts')
const { i18n } = await import('#shared/i18n.ts')

export {}

const now = new Date('2021-04-13T11:10:00Z')

const renderDateField = async (
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
    formField: true,
  })
}

describe('Fields - FieldDate', () => {
  beforeEach(() => {
    i18n.setTranslationMap(new Map())
  })

  beforeAll(() => {
    vi.useFakeTimers().setSystemTime(now)
  })

  afterAll(() => {
    vi.useRealTimers()
  })

  describe('type "date"', () => {
    it('renders input and allows selecting date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.click(input)
      await view.events.click(view.getByText('12'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-12')
      expect(input).toHaveDisplayValue('2021-04-12')
    })

    it('renders input and allows typing date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.type(input, '2021-04-12')
      await view.events.keyboard('{Enter}')

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-12')
      expect(input).toHaveDisplayValue('2021-04-12')
    })

    it('renders input and allows selecting a date range', async () => {
      const view = await renderDateField({
        range: true,
      })

      const input = view.getByLabelText('Date')
      expect(input).toHaveDisplayValue('')

      await view.events.click(input)
      await view.events.click(view.getByText('12'))
      await view.events.click(view.getByText('14'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toEqual(['2021-04-12', '2021-04-14'])
      expect(input).toHaveDisplayValue('2021-04-12 - 2021-04-14')
    })

    it('renders input and allows typing date range', async () => {
      const view = await renderDateField({
        range: true,
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.type(input, '2021-04-12 - 2021-04-14')
      await view.events.keyboard('{Enter}')

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toEqual(['2021-04-12', '2021-04-14'])
      expect(input).toHaveDisplayValue('2021-04-12 - 2021-04-14')
    })

    it('renders input and allows selecting today', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')
      expect(input).toHaveDisplayValue('')

      await view.events.click(input)
      await view.events.click(view.getByText('Today'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-13')
      expect(input).toHaveDisplayValue('2021-04-13')
    })

    it('sets the default date', async () => {
      const view = await renderDateField({
        value: '2020-02-10',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('2020-02-10')
    })

    it('allows to clear value', async () => {
      const view = await renderDateField({
        value: '2020-02-10',
        clearable: true,
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('2020-02-10')

      await view.events.click(view.getByLabelText('Clear Selection'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBeNull()
      expect(input).toHaveDisplayValue('')
    })

    it("doesn't allow changing anything while disabled", async () => {
      const view = await renderDateField({
        disabled: true,
        value: '2020-02-10',
      })

      const input = view.getByLabelText('Date')

      expect(input).toBeDisabled()

      await view.events.click(view.getByText('Today'))

      expect(input).toHaveDisplayValue('2020-02-10')
    })

    it('disables days before today, if futureOnly present', async () => {
      const view = await renderDateField({
        futureOnly: true,
      })
      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(view.getByText('12'))

      expect(input).toHaveDisplayValue('')

      await view.events.click(view.getByText('13'))

      expect(input).toHaveDisplayValue('2021-04-13')
    })

    it('rerenders props', async () => {
      const view = await renderDateField({
        maxDate: '2021-04-14',
      })

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(view.getByText('15'))

      expect(input).toHaveDisplayValue('')

      await view.rerender({
        maxDate: '2021-04-15',
      })

      await view.events.click(view.getByText('15'))

      expect(input).toHaveDisplayValue('2021-04-15')
    })
  })

  describe('type "datetime"', () => {
    it('renders input and allows selecting today', async () => {
      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.click(input)
      await view.events.click(view.getByText('Today'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-13T11:10:00.000Z')
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('renders input and allows entering timestamp', async () => {
      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.type(input, '2021-04-13 11:10')
      await view.events.keyboard('{Enter}')

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-13T11:10:00.000Z')
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('renders AM/PM, if needed', async () => {
      i18n.setTranslationMap(
        new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]),
      )

      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('')

      await view.events.click(input)
      await view.events.click(view.getByText('Today'))

      expect(input).toHaveDisplayValue('04/13/2021 11:10 am')
    })
  })
})
