// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Jalali (Solar Hijri / Shamsi) calendar utilities.
// Conversion algorithm adapted from jalaali-js (MIT licence).
// https://github.com/jalaali/jalaali-js

function _div(a: number, b: number): number {
  return ~~(a / b)
}

function _mod(a: number, b: number): number {
  return a - ~~(a / b) * b
}

function jalCal(jy: number): { leap: number; gy: number; march: number } {
  const breaks = [
    -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324,
    2394, 2456, 3178,
  ]
  const gy = jy + 621
  let leapJ = -14
  let jp = breaks[0]

  for (let i = 1; i < breaks.length; i++) {
    const jm = breaks[i]
    const jump = jm - jp
    if (jy < jm) {
      let n = jy - jp
      leapJ += _div(n, 33) * 8 + _div(_mod(n, 33), 4)
      const leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150
      const march = 20 + leapJ - leapG
      if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33
      let leap = _mod(_mod(n + 1, 33) - 1, 4)
      if (leap === -1) leap = 4
      return { leap, gy, march }
    }
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4)
    jp = jm
  }
  throw new Error(`Jalali year ${jy} is outside the supported range.`)
}

function g2d(gy: number, gm: number, gd: number): number {
  return (
    _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
    _div(153 * _mod(gm + 9, 12) + 2, 5) +
    gd -
    34840408 -
    _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) +
    752
  )
}

function d2g(jdn: number): { gy: number; gm: number; gd: number } {
  let j = 4 * jdn + 139361631
  j += _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908
  const i = _div(_mod(j, 1461), 4) * 5 + 308
  const gd = _div(_mod(i, 153), 5) + 1
  const gm = _mod(_div(i, 153), 12) + 1
  const gy = _div(j, 1461) - 100100 + _div(8 - gm, 6)
  return { gy, gm, gd }
}

function j2d(jy: number, jm: number, jd: number): number {
  const r = jalCal(jy)
  return g2d(r.gy, 3, r.march) + (jm - 1) * 30 + Math.min(jm, 7) - 1 + jd - 1
}

function d2j(jdn: number): { jy: number; jm: number; jd: number } {
  const { gy } = d2g(jdn)
  let jy = gy - 621
  const r = jalCal(jy)
  const jdn1f = g2d(gy, 3, r.march)
  let k = jdn - jdn1f
  let jm: number
  let jd: number
  if (k >= 0) {
    if (k <= 185) {
      return { jy, jm: 1 + _div(k, 31), jd: _mod(k, 31) + 1 }
    }
    k -= 186
  } else {
    jy -= 1
    k += 179
    if (jalCal(jy).leap === 1) k += 1
  }
  jm = 7 + _div(k, 30)
  jd = _mod(k, 30) + 1
  return { jy, jm, jd }
}

// ── Public API ────────────────────────────────────────────────────────────────

/** Convert a Gregorian Date to Jalali {jy, jm, jd}. */
export function dateToJalali(date: Date): { jy: number; jm: number; jd: number } {
  return d2j(g2d(date.getFullYear(), date.getMonth() + 1, date.getDate()))
}

/** Convert a Jalali {jy, jm, jd} to a Gregorian Date. */
export function jalaliToDate(jy: number, jm: number, jd: number): Date {
  const { gy, gm, gd } = d2g(j2d(jy, jm, jd))
  return new Date(gy, gm - 1, gd)
}

/** Number of days in a given Jalali month. */
export function jalaliMonthLength(jy: number, jm: number): number {
  if (jm <= 6) return 31
  if (jm <= 11) return 30
  return jalCal(jy).leap === 0 ? 30 : 29
}

export const JALALI_MONTH_NAMES = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
] as const

/** Week-day short names starting from Saturday (Iranian week start). */
export const JALALI_WEEKDAY_SHORT = ['ش', 'ی', 'د', 'سه', 'چ', 'پ', 'ج'] as const

export function jalaliMonthName(jm: number): string {
  return JALALI_MONTH_NAMES[jm - 1] ?? ''
}

/** Replace ASCII digits 0-9 with Eastern Arabic (Persian) equivalents. */
export function toPersianDigits(value: string | number): string {
  return String(value).replace(/[0-9]/g, (d) => String.fromCharCode(0x06f0 + Number(d)))
}
