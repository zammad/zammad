// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The locale's date format in Zammad's own tokens, split into the groups of a date and written
// as `date-fns` tokens.

export type SegmentKind = 'year' | 'month' | 'day' | 'hour' | 'minute' | 'second' | 'meridiem'

export const TIME_KINDS = new Set<SegmentKind>(['hour', 'minute', 'second', 'meridiem'])

export interface SegmentSpec {
  kind: SegmentKind
  length: number
  placeholder: string
  min: number
  max: number
  // The `date-fns` token the segment is written and parsed with.
  token: string
}

export type FormatPart =
  | { type: 'literal'; text: string }
  | { type: 'segment'; spec: SegmentSpec; index: number }

// Zammad's placeholders: 'd'/'dd' day, 'm'/'mm' month, 'yyyy'/'yy' year, 'HH' hour, 'l' hour of
// the 12-hour clock, 'MM' minute, 'SS' second, 'P' meridiem.
const SEGMENT_SPECS: Record<string, SegmentSpec> = {
  yyyy: { kind: 'year', length: 4, placeholder: 'YYYY', min: 1, max: 9999, token: 'yyyy' },
  yy: { kind: 'year', length: 2, placeholder: 'YY', min: 0, max: 99, token: 'yy' },
  mm: { kind: 'month', length: 2, placeholder: 'MM', min: 1, max: 12, token: 'MM' },
  dd: { kind: 'day', length: 2, placeholder: 'DD', min: 1, max: 31, token: 'dd' },
  HH: { kind: 'hour', length: 2, placeholder: 'hh', min: 0, max: 23, token: 'HH' },
  l: { kind: 'hour', length: 2, placeholder: 'hh', min: 1, max: 12, token: 'hh' },
  MM: { kind: 'minute', length: 2, placeholder: 'mm', min: 0, max: 59, token: 'mm' },
  SS: { kind: 'second', length: 2, placeholder: 'ss', min: 0, max: 59, token: 'ss' },
  P: { kind: 'meridiem', length: 2, placeholder: 'pp', min: 0, max: 1, token: 'aaa' },
}

SEGMENT_SPECS.m = SEGMENT_SPECS.mm
SEGMENT_SPECS.d = SEGMENT_SPECS.dd

const TOKEN_PATTERN = /yyyy|yy|mm|dd|HH|MM|SS|m|d|l|P/g

export const buildFormatParts = (localeFormat: string) => {
  const parts: FormatPart[] = []
  let index = 0
  let cursor = 0

  for (const match of localeFormat.matchAll(TOKEN_PATTERN)) {
    if (match.index > cursor) {
      parts.push({ type: 'literal', text: localeFormat.slice(cursor, match.index) })
    }

    parts.push({ type: 'segment', spec: SEGMENT_SPECS[match[0]], index })
    index += 1
    cursor = match.index + match[0].length
  }

  if (cursor < localeFormat.length) {
    parts.push({ type: 'literal', text: localeFormat.slice(cursor) })
  }

  return parts
}

export const toDateFnsFormat = (parts: FormatPart[]) =>
  parts
    .map((part) => {
      if (part.type === 'segment') return part.spec.token
      return /[a-z]/i.test(part.text) ? `'${part.text}'` : part.text
    })
    .join('')

export type YearWindow = 'around' | 'future' | 'past'

// A year typed with one or two digits lands in a window of a hundred years that slides with the
// current date: around it by default, ahead of it for a field that takes the future only, and
// behind it for one that takes the past only.
export const expandYear = (digits: string, window: YearWindow = 'around', now = new Date()) => {
  if (digits.length > 2) return digits

  const current = now.getFullYear()

  let start = current - 50
  if (window === 'future') start = current
  else if (window === 'past') start = current - 99

  let year = Math.floor(start / 100) * 100 + Number(digits)
  if (year < start) year += 100

  return String(year)
}

// A pasted or typed one- or two-digit value of a four-digit year group is completed within the
// year window, any other group keeps its digits.
export const completeYear = (spec: SegmentSpec, digits: string, window?: YearWindow) =>
  spec.kind === 'year' && spec.length === 4 ? expandYear(digits, window) : digits
