// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

const { FormKit } = await import('@formkit/vue')
const { getNode } = await import('@formkit/core')
const { EnumAppearanceTheme } = await import('#shared/graphql/types.ts')
const { renderComponent } = await import('#tests/support/components/index.ts')
const { mockMediaTheme } = await import('#tests/support/mock-mediaTheme.ts')
const { waitForNextTick } = await import('#tests/support/utils.ts')
const { i18n } = await import('#shared/i18n.ts')

vi.mock('@vueuse/core', async () => {
  const mod = await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')

  return {
    ...mod,
    usePreferredColorScheme: () => computed(() => 'dark'),
  }
})

const now = new Date('2021-04-13T11:10:00Z')

const renderDateField = async (props: Record<string, unknown> = {}, options: any = {}) => {
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

describe('Fields - FieldDate', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
    i18n.setTranslationMap(new Map())
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('type "date"', () => {
    it('renders input and allows selecting date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.events.click(input)
      await view.events.click(await view.findByText('12'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-12')
      expect(input).toHaveDisplayValue('2021-04-12')
    })

    it('renders input and allows typing date', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

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

      expect(input).toHaveDisplayValue('YYYY-MM-DD - YYYY-MM-DD')

      await view.events.click(input)

      expect(view.queryByText('Today')).not.toBeInTheDocument()

      await view.events.click(await view.findByText('12'))
      await view.events.click(view.getByText('14'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toEqual(['2021-04-12', '2021-04-14'])
      expect(input).toHaveDisplayValue('2021-04-12 - 2021-04-14')
    })

    it('with partialRange disabled, commits only a complete range (no partial [from, null])', async () => {
      const view = await renderDateField({ range: true, partialRange: false })

      expect(getNode('date')?.props.partialRange).toBe(false)

      const input = view.getByLabelText('Date')
      await view.events.click(input)

      // A single date must not reach the form value as a partial `[from, null]`.
      await view.events.click(await view.findByText('12'))
      expect(getNode('date')?._value).not.toEqual(['2021-04-12', null])

      // Completing the range commits the full `[from, to]`.
      await view.events.click(view.getByText('14'))
      expect(getNode('date')?._value).toEqual(['2021-04-12', '2021-04-14'])
    })

    it('renders input and allows typing date range', async () => {
      const view = await renderDateField({
        range: true,
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD - YYYY-MM-DD')

      await view.events.type(input, '2021-04-12 - 2021-04-14')
      await view.events.keyboard('{Enter}')

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toEqual(['2021-04-12', '2021-04-14'])
      expect(input).toHaveDisplayValue('2021-04-12 - 2021-04-14')
    })

    it('self-heals a reversed typed range by swapping the bounds', async () => {
      const view = await renderDateField({
        range: true,
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD - YYYY-MM-DD')

      await view.events.type(input, '2021-04-28 - 2021-04-14')
      await view.events.keyboard('{Enter}')

      vi.runAllTimers()
      await waitForNextTick()

      // Reordered by the `healDateRange` feature instead of raising an error.
      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>
      expect(emittedInput.at(-1)?.[0]).toEqual(['2021-04-14', '2021-04-28'])
      expect(input).toHaveDisplayValue('2021-04-14 - 2021-04-28')
    })

    it('heals a reversed range set from outside (programmatic input)', async () => {
      await renderDateField({ range: true })

      getNode('date')?.input(['2021-04-28', '2021-04-14'])
      await waitForNextTick()

      expect(getNode('date')?._value).toEqual(['2021-04-14', '2021-04-28'])
    })

    it('heals a reversed range provided as the initial value', async () => {
      await renderDateField({ range: true, value: ['2021-04-28', '2021-04-14'] })
      await waitForNextTick()

      expect(getNode('date')?._value).toEqual(['2021-04-14', '2021-04-28'])
    })

    it('renders input and allows selecting today', async () => {
      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.events.click(input)
      await view.events.click(await view.findByText('Today'))

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

      await view.events.click(view.getByLabelText('Clear selection'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBeNull()
      expect(input).toHaveDisplayValue('YYYY-MM-DD')
    })

    it("doesn't allow changing anything while disabled", async () => {
      const view = await renderDateField({
        disabled: true,
      })

      const input = view.getByLabelText('Date')

      expect(input).toBeDisabled()

      await view.events.click(input)

      expect(view.queryByText('Today')).not.toBeInTheDocument()
    })

    it('disables days after today, if pastOnly present', async () => {
      const view = await renderDateField({
        pastOnly: true,
      })

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(await view.findByText('14'))

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.events.click(view.getByText('13'))

      expect(input).toHaveDisplayValue('2021-04-13')
    })

    it('disables days before today, if futureOnly present', async () => {
      const view = await renderDateField({
        futureOnly: true,
      })

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(await view.findByText('12'))

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.events.click(view.getByText('13'))

      expect(input).toHaveDisplayValue('2021-04-13')
    })

    it('rerenders props', async () => {
      const view = await renderDateField({
        maxDate: '2021-04-14',
      })

      const input = view.getByLabelText('Date')

      await view.events.click(input)
      await view.events.click(await view.findByText('15'))

      expect(input).toHaveDisplayValue('YYYY-MM-DD')

      await view.rerender({
        maxDate: '2021-04-15',
      })

      await view.events.click(input)
      await view.events.click(await view.findByText('15'))

      expect(input).toHaveDisplayValue('2021-04-15')
    })

    it('renders in dark mode when user prefers dark media theme', async () => {
      mockMediaTheme(EnumAppearanceTheme.Dark)

      const view = await renderDateField()

      const input = view.getByLabelText('Date')

      await view.events.click(input)

      const dialog = await view.findByRole('dialog')

      expect(dialog).toHaveClass('dp--theme-dark')
    })
  })

  describe('type "datetime"', () => {
    it('renders input and allows selecting today', async () => {
      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD hh:mm')

      await view.events.click(input)
      await view.events.click(await view.findByText('Today'))

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-13T11:10:00Z')
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
    })

    it('renders input and allows entering timestamp', async () => {
      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('YYYY-MM-DD hh:mm')

      await view.events.type(input, '2021-04-13 11:10')
      await view.events.keyboard('{Enter}')

      const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

      expect(emittedInput[0][0]).toBe('2021-04-13T11:10:00Z')
      expect(input).toHaveDisplayValue('2021-04-13 11:10')
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
      const view = await renderDateField({
        type: 'datetime',
        value,
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue(display)
    })

    it('renders AM/PM, if needed', async () => {
      i18n.setTranslationMap(new Map([['FORMAT_DATETIME', 'mm/dd/yyyy l:MM P']]))

      const view = await renderDateField({
        type: 'datetime',
      })

      const input = view.getByLabelText('Date')

      expect(input).toHaveDisplayValue('MM/DD/YYYY hh:mm pp')

      await view.events.click(input)
      await view.events.click(await view.findByText('Today'))

      expect(input).toHaveDisplayValue('04/13/2021 11:10 am')
    })
  })
})
