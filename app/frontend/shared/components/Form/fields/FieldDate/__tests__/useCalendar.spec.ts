// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, ref } from 'vue'

import {
  buildDecadeYears,
  buildMonthWeeks,
  isDayDisabled,
  isMonthDisabled,
  isYearDisabled,
  mergeTime,
  useCalendar,
  type UseCalendarOptions,
} from '../useCalendar.ts'

const now = new Date('2021-04-13T11:10:00')

const day = (value: string) => new Date(`${value}T00:00:00`)

const setup = (overrides: Partial<UseCalendarOptions> = {}) => {
  const onCommit = vi.fn()
  const onDone = vi.fn()

  const calendar = useCalendar({
    selected: ref(undefined),
    bounds: ref({}),
    withTime: ref(false),
    weekStart: ref(1),
    onCommit,
    onDone,
    ...overrides,
  })

  return { calendar, onCommit, onDone }
}

describe('useCalendar', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('grids', () => {
    it('builds the weeks of a month from the configured week start', () => {
      const weeks = buildMonthWeeks(day('2021-04-01'), 1)

      expect(weeks).toHaveLength(5)
      expect(weeks[0][0]).toEqual(day('2021-03-29'))
      expect(weeks[4][6]).toEqual(day('2021-05-02'))

      expect(buildMonthWeeks(day('2021-04-01'), 0)[0][0]).toEqual(day('2021-03-28'))
    })

    it('builds the decade of a year', () => {
      const years = buildDecadeYears(day('2021-04-13')).map((year) => year.getFullYear())

      expect(years).toEqual([2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029])
    })
  })

  describe('bounds', () => {
    it('disables days outside of the bounds or refused by the callback', () => {
      const bounds = {
        minDate: '2021-04-10',
        maxDate: day('2021-04-20'),
        disabledDays: (date: Date) => date.getDay() === 0,
      }

      expect(isDayDisabled(day('2021-04-09'), bounds)).toBe(true)
      expect(isDayDisabled(day('2021-04-10'), bounds)).toBe(false)
      expect(isDayDisabled(day('2021-04-20'), bounds)).toBe(false)
      expect(isDayDisabled(day('2021-04-21'), bounds)).toBe(true)
      expect(isDayDisabled(day('2021-04-18'), bounds)).toBe(true)
    })

    it('keeps months and years enabled while one of their days is within the bounds', () => {
      const bounds = { minDate: '2021-04-10', maxDate: '2022-01-05' }

      expect(isMonthDisabled(day('2021-03-01'), bounds)).toBe(true)
      expect(isMonthDisabled(day('2021-04-01'), bounds)).toBe(false)
      expect(isMonthDisabled(day('2022-01-01'), bounds)).toBe(false)
      expect(isMonthDisabled(day('2022-02-01'), bounds)).toBe(true)

      expect(isYearDisabled(day('2020-01-01'), bounds)).toBe(true)
      expect(isYearDisabled(day('2022-01-01'), bounds)).toBe(false)
      expect(isYearDisabled(day('2023-01-01'), bounds)).toBe(true)
    })

    it('ignores the selection of a disabled day', () => {
      const { calendar, onCommit } = setup({ bounds: ref({ minDate: '2021-04-15' }) })

      calendar.select(day('2021-04-14'))

      expect(onCommit).not.toHaveBeenCalled()
    })
  })

  describe('time', () => {
    it('defaults the time of a picked date to the morning, or keeps the current one', () => {
      expect(mergeTime(day('2021-04-15'))).toEqual(new Date('2021-04-15T08:00:00'))
      expect(mergeTime(day('2021-04-15'), new Date('2021-04-13T17:45:00'))).toEqual(
        new Date('2021-04-15T17:45:00'),
      )
    })
  })

  describe('panel flow', () => {
    it('commits a picked day and finishes', () => {
      const { calendar, onCommit, onDone } = setup()

      expect(calendar.panel.value).toBe('day')

      calendar.select(day('2021-04-15'))

      expect(onCommit).toHaveBeenCalledWith(day('2021-04-15'))
      expect(onDone).toHaveBeenCalled()
    })

    it('continues to the time panel after a picked day', () => {
      const { calendar, onCommit, onDone } = setup({ withTime: ref(true) })

      calendar.select(day('2021-04-15'))

      expect(onCommit).toHaveBeenCalledWith(new Date('2021-04-15T08:00:00'))
      expect(onDone).not.toHaveBeenCalled()
      expect(calendar.panel.value).toBe('time')

      calendar.stepUp()

      expect(calendar.panel.value).toBe('day')
    })

    it('picks today from any date panel', () => {
      const { calendar, onCommit, onDone } = setup({ withTime: ref(true) })

      calendar.stepUp()
      calendar.stepUp()
      calendar.next()
      calendar.selectToday()

      expect(onCommit).toHaveBeenCalledWith(new Date('2021-04-13T08:00:00'))
      expect(onDone).not.toHaveBeenCalled()
      expect(calendar.panel.value).toBe('time')
      expect(calendar.visibleMonth.value).toEqual(day('2021-04-01'))
    })

    it('refuses today when the bounds exclude it', () => {
      const { calendar, onCommit } = setup({ bounds: ref({ minDate: '2021-04-14' }) })

      expect(calendar.isTodayDisabled.value).toBe(true)

      calendar.selectToday()

      expect(onCommit).not.toHaveBeenCalled()
    })

    it('drills back down after stepping up through the header', () => {
      const { calendar, onCommit } = setup()

      calendar.stepUp()
      expect(calendar.panel.value).toBe('month')

      calendar.stepUp()
      expect(calendar.panel.value).toBe('year')
      expect(calendar.canStepUp.value).toBe(false)

      calendar.select(day('2024-01-01'))
      expect(calendar.panel.value).toBe('month')

      calendar.select(day('2024-02-01'))
      expect(calendar.panel.value).toBe('day')
      expect(calendar.focusedDate.value).toEqual(day('2024-02-13'))

      calendar.select(day('2024-02-29'))
      expect(onCommit).toHaveBeenCalledWith(day('2024-02-29'))
    })

    it('clamps the day of the month when the target month is shorter', () => {
      const { calendar } = setup({ selected: ref(day('2021-03-31')) })

      calendar.stepUp()
      calendar.select(day('2021-02-01'))

      expect(calendar.focusedDate.value).toEqual(day('2021-02-28'))
    })
  })

  describe('initial view', () => {
    it('opens on today, or on the selected day', () => {
      expect(setup().calendar.visibleMonth.value).toEqual(day('2021-04-01'))

      const { calendar } = setup({ selected: ref(day('2021-12-24')) })

      expect(calendar.focusedDate.value).toEqual(day('2021-12-24'))
      expect(calendar.visibleMonth.value).toEqual(day('2021-12-01'))
    })

    it('opens on the nearest bound when today lies outside of the bounds', () => {
      const future = setup({ bounds: ref({ minDate: day('2021-06-10') }) }).calendar

      expect(future.focusedDate.value).toEqual(day('2021-06-10'))
      expect(future.visibleMonth.value).toEqual(day('2021-06-01'))

      const past = setup({ bounds: ref({ maxDate: new Date('2020-02-20T15:00:00') }) }).calendar

      expect(past.focusedDate.value).toEqual(day('2020-02-20'))
      expect(past.visibleMonth.value).toEqual(day('2020-02-01'))
    })

    it('follows a selection that changes while it is shown', async () => {
      const selected = ref<Date | undefined>(undefined)
      const { calendar } = setup({ selected })

      selected.value = new Date('2021-12-24T09:30:00')
      await nextTick()

      expect(calendar.focusedDate.value).toEqual(day('2021-12-24'))
      expect(calendar.visibleMonth.value).toEqual(day('2021-12-01'))

      selected.value = new Date('2021-12-24T16:45:00')
      await nextTick()

      expect(calendar.visibleMonth.value).toEqual(day('2021-12-01'))
    })
  })

  describe('navigation', () => {
    it('shifts the visible month with the header buttons', () => {
      const { calendar } = setup()

      expect(calendar.visibleMonth.value).toEqual(day('2021-04-01'))

      calendar.next()

      expect(calendar.visibleMonth.value).toEqual(day('2021-05-01'))
      expect(calendar.focusedDate.value).toEqual(day('2021-05-13'))

      calendar.prev()
      calendar.prev()

      expect(calendar.visibleMonth.value).toEqual(day('2021-03-01'))
    })

    it('moves the focused day with the keyboard and keeps it in view', () => {
      const { calendar } = setup()

      expect(calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })).toBe(true)
      expect(calendar.focusedDate.value).toEqual(day('2021-04-14'))

      calendar.moveFocus({ key: 'ArrowLeft', shiftKey: false })
      calendar.moveFocus({ key: 'ArrowUp', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-06'))

      calendar.moveFocus({ key: 'Home', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-05'))

      calendar.moveFocus({ key: 'End', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-11'))

      calendar.moveFocus({ key: 'ArrowDown', shiftKey: false })
      calendar.moveFocus({ key: 'ArrowDown', shiftKey: false })
      calendar.moveFocus({ key: 'ArrowDown', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-05-02'))
      expect(calendar.visibleMonth.value).toEqual(day('2021-05-01'))

      calendar.moveFocus({ key: 'PageUp', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-02'))
      expect(calendar.visibleMonth.value).toEqual(day('2021-04-01'))

      calendar.moveFocus({ key: 'PageDown', shiftKey: true })
      expect(calendar.focusedDate.value).toEqual(day('2022-04-02'))

      expect(calendar.moveFocus({ key: 'a', shiftKey: false })).toBe(false)
    })

    it('skips disabled days with the keyboard', () => {
      const { calendar } = setup({
        selected: ref(day('2021-04-16')),
        bounds: ref({
          minDate: '2021-04-13',
          disabledDays: (date: Date) => date.getDay() === 0 || date.getDay() === 6,
        }),
      })

      calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-19'))

      expect(calendar.moveFocus({ key: 'ArrowUp', shiftKey: false })).toBe(true)
      expect(calendar.focusedDate.value).toEqual(day('2021-04-19'))

      calendar.moveFocus({ key: 'ArrowLeft', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-16'))

      calendar.moveFocus({ key: 'Home', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-16'))

      calendar.moveFocus({ key: 'End', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-19'))
    })

    it('skips disabled months and years with the keyboard', () => {
      const { calendar } = setup({ bounds: ref({ maxDate: '2021-06-30' }) })

      calendar.stepUp()
      calendar.moveFocus({ key: 'ArrowDown', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-04-13'))

      calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })
      calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })
      calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-06-13'))

      calendar.stepUp()
      calendar.moveFocus({ key: 'ArrowRight', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-06-13'))

      calendar.moveFocus({ key: 'ArrowLeft', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2020-06-13'))
    })

    it('moves the focused month and year with the keyboard', () => {
      const { calendar } = setup()

      calendar.stepUp()
      calendar.moveFocus({ key: 'ArrowDown', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-07-13'))

      calendar.moveFocus({ key: 'End', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2021-12-13'))

      calendar.stepUp()
      calendar.moveFocus({ key: 'ArrowUp', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2016-12-13'))

      calendar.moveFocus({ key: 'Home', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2010-12-13'))
      expect(calendar.years.value[0].getFullYear()).toBe(2010)

      calendar.moveFocus({ key: 'PageDown', shiftKey: false })
      expect(calendar.focusedDate.value).toEqual(day('2020-12-13'))
    })
  })
})
