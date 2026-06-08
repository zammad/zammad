// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { validDateTime, isDateString, getTimestampWithDiff } from '../datetime.ts'

describe('validDateTime', () => {
  it('is a valid date with time', () => {
    expect(validDateTime('2024-10-10T06:00:00Z')).toBe(true)
  })

  it('is a valid date', () => {
    expect(validDateTime('2024-10-10')).toBe(true)
  })

  it('is a valid date with time', () => {
    expect(validDateTime('2024-02-20 14:29:07 UTC')).toBe(true)
  })

  it('is a invalid date', () => {
    expect(validDateTime('2024+10-10T06:00:00Z')).toBe(false)
  })

  it('is also an invalid date', () => {
    expect(validDateTime('Test 456')).toBe(false)
  })
})

describe('isDateString', () => {
  it('is a valid date string only', () => {
    expect(isDateString('2024-10-10')).toBe(true)
  })

  it('is a valid date', () => {
    expect(isDateString('2024-10-10T06:00:00Z')).toBe(false)
  })
})

describe('getTimestampWithDiff', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-02-09T12:00:00.000Z'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('returns a future ISO timestamp with positive minutes diff', () => {
    expect(getTimestampWithDiff(30)).toBe('2026-02-09T12:30:00Z')
  })

  it('returns a past ISO timestamp with negative minutes diff', () => {
    expect(getTimestampWithDiff(-45)).toBe('2026-02-09T11:15:00Z')
  })

  it('returns a future ISO timestamp with positive hours diff', () => {
    expect(getTimestampWithDiff(3, 'hours')).toBe('2026-02-09T15:00:00Z')
  })

  it('returns a past ISO timestamp with negative hours diff', () => {
    expect(getTimestampWithDiff(-2, 'hours')).toBe('2026-02-09T10:00:00Z')
  })

  it('returns the current ISO timestamp when diff is 0', () => {
    expect(getTimestampWithDiff(0)).toBe('2026-02-09T12:00:00Z')
  })

  it('defaults to minutes unit and iso format', () => {
    const resultDefault = getTimestampWithDiff(60)
    const resultExplicit = getTimestampWithDiff(60, 'minutes', 'iso')

    expect(resultDefault).toBe(resultExplicit)
  })

  it('returns a date string when returnFormat is date', () => {
    expect(getTimestampWithDiff(0, 'minutes', 'date')).toBe('2026-02-09')
  })

  it('returns a future date string with positive diff', () => {
    expect(getTimestampWithDiff(24, 'hours', 'date')).toBe('2026-02-10')
  })

  it('returns a past date string with negative diff', () => {
    expect(getTimestampWithDiff(-24, 'hours', 'date')).toBe('2026-02-08')
  })

  it('crosses day boundary correctly for date format', () => {
    // 13 hours forward from 12:00 UTC = next day 01:00 UTC
    expect(getTimestampWithDiff(13, 'hours', 'date')).toBe('2026-02-10')
  })
})
