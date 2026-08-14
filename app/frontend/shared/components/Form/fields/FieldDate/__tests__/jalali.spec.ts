// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect } from 'vitest'

import {
  dateToJalali,
  jalaliToDate,
  jalaliMonthLength,
  jalaliMonthName,
  toPersianDigits,
  JALALI_WEEKDAY_SHORT,
} from '../jalali.ts'

describe('dateToJalali', () => {
  it('converts a well-known Gregorian date to Jalali', () => {
    // 14 August 2026 → 23 Mordad 1405
    const result = dateToJalali(new Date(2026, 7, 14))
    expect(result).toEqual({ jy: 1405, jm: 5, jd: 23 })
  })

  it('converts the Nowruz (Persian New Year) correctly', () => {
    // 20 March 2025 → 1 Farvardin 1404
    const result = dateToJalali(new Date(2025, 2, 20))
    expect(result).toEqual({ jy: 1404, jm: 1, jd: 1 })
  })
})

describe('jalaliToDate', () => {
  it('round-trips through Gregorian correctly', () => {
    const original = new Date(2026, 7, 14) // 14 Aug 2026
    const { jy, jm, jd } = dateToJalali(original)
    const back = jalaliToDate(jy, jm, jd)
    expect(back.getFullYear()).toBe(original.getFullYear())
    expect(back.getMonth()).toBe(original.getMonth())
    expect(back.getDate()).toBe(original.getDate())
  })
})

describe('jalaliMonthLength', () => {
  it('returns 31 for the first 6 months', () => {
    for (let m = 1; m <= 6; m++) {
      expect(jalaliMonthLength(1405, m)).toBe(31)
    }
  })

  it('returns 30 for months 7–11', () => {
    for (let m = 7; m <= 11; m++) {
      expect(jalaliMonthLength(1405, m)).toBe(30)
    }
  })

  it('returns 29 for month 12 in a non-leap year', () => {
    expect(jalaliMonthLength(1405, 12)).toBe(29)
  })
})

describe('jalaliMonthName', () => {
  it('returns فروردین for month 1', () => {
    expect(jalaliMonthName(1)).toBe('فروردین')
  })

  it('returns مرداد for month 5', () => {
    expect(jalaliMonthName(5)).toBe('مرداد')
  })

  it('returns اسفند for month 12', () => {
    expect(jalaliMonthName(12)).toBe('اسفند')
  })
})

describe('toPersianDigits', () => {
  it('converts ASCII digits to Eastern Arabic equivalents', () => {
    expect(toPersianDigits(1405)).toBe('۱۴۰۵')
    expect(toPersianDigits('23')).toBe('۲۳')
  })
})

describe('JALALI_WEEKDAY_SHORT', () => {
  it('starts with Saturday (ش)', () => {
    expect(JALALI_WEEKDAY_SHORT[0]).toBe('ش')
  })

  it('ends with Friday (ج)', () => {
    expect(JALALI_WEEKDAY_SHORT[6]).toBe('ج')
  })
})
