// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { buildFormatParts, completeYear, expandYear, toDateFnsFormat } from '../dateFormat.ts'

describe('dateFormat', () => {
  it('splits a locale format into groups and literals', () => {
    const parts = buildFormatParts('dd.mm.yyyy HH:MM')

    expect(
      parts.map((part) => (part.type === 'literal' ? part.text : `<${part.spec.kind}>`)),
    ).toEqual(['<day>', '.', '<month>', '.', '<year>', ' ', '<hour>', ':', '<minute>'])
  })

  it('writes the groups as date-fns tokens', () => {
    expect(toDateFnsFormat(buildFormatParts('yyyy-mm-dd HH:MM'))).toBe('yyyy-MM-dd HH:mm')
    expect(toDateFnsFormat(buildFormatParts('mm/dd/yyyy l:MM P'))).toBe('MM/dd/yyyy hh:mm aaa')
    expect(toDateFnsFormat(buildFormatParts('d.m.yy'))).toBe('dd.MM.yy')
  })

  it('completes a short year within a window of a hundred years around now', () => {
    const now = new Date('2026-10-21T00:00:00')

    expect(expandYear('0', 'around', now)).toBe('2000')
    expect(expandYear('7', 'around', now)).toBe('2007')
    expect(expandYear('26', 'around', now)).toBe('2026')
    expect(expandYear('75', 'around', now)).toBe('2075')
    expect(expandYear('76', 'around', now)).toBe('1976')
    expect(expandYear('99', 'around', now)).toBe('1999')
    expect(expandYear('202', 'around', now)).toBe('202')
    expect(expandYear('2021', 'around', now)).toBe('2021')
  })

  it('completes a short year ahead of now for the future and behind it for the past', () => {
    const now = new Date('2026-10-21T00:00:00')

    expect(expandYear('26', 'future', now)).toBe('2026')
    expect(expandYear('25', 'future', now)).toBe('2125')
    expect(expandYear('99', 'future', now)).toBe('2099')

    expect(expandYear('26', 'past', now)).toBe('2026')
    expect(expandYear('27', 'past', now)).toBe('1927')
    expect(expandYear('99', 'past', now)).toBe('1999')
  })

  it('completes a short value of a four-digit year group only', () => {
    const [year, month, shortYear] = buildFormatParts('yyyy.mm.yy').flatMap((part) =>
      part.type === 'segment' ? [part.spec] : [],
    )

    expect(completeYear(year, '26', 'past')).toBe(String(expandYear('26', 'past')))
    expect(completeYear(year, '2026')).toBe('2026')
    expect(completeYear(month, '4')).toBe('4')
    expect(completeYear(shortYear, '26')).toBe('26')
  })

  it('treats the single-letter day and month placeholders as two-digit groups', () => {
    const parts = buildFormatParts('d.m.yyyy')

    expect(parts.flatMap((part) => (part.type === 'segment' ? [part.spec.length] : []))).toEqual([
      2, 2, 4,
    ])
  })
})
