// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { deaccent, splitLabelByMatch } from '#shared/utils/labelMatching.ts'

describe('deaccent', () => {
  it('strips every combining mark, not only the first one', () => {
    expect(deaccent('E\u0301milie Mu\u0308ller')).toBe('Emilie Muller')
  })

  it('strips combining marks from precomposed characters', () => {
    expect(deaccent('Émilie Müller')).toBe('Emilie Muller')
  })

  it('leaves text without combining marks untouched', () => {
    expect(deaccent('Zammad')).toBe('Zammad')
  })
})

describe('splitLabelByMatch', () => {
  it('returns the whole text as the leading fragment without a keyword', () => {
    expect(splitLabelByMatch('Zammad Foundation')).toEqual({
      before: 'Zammad Foundation',
      matched: '',
      after: '',
    })
  })

  it('returns the whole text as the leading fragment for a whitespace-only keyword', () => {
    expect(splitLabelByMatch('Zammad Foundation', '   ')).toEqual({
      before: 'Zammad Foundation',
      matched: '',
      after: '',
    })
  })

  it('returns the whole text as the leading fragment when the keyword does not occur', () => {
    expect(splitLabelByMatch('Zammad Foundation', 'missing')).toEqual({
      before: 'Zammad Foundation',
      matched: '',
      after: '',
    })
  })

  it('splits around the first occurrence of the keyword', () => {
    expect(splitLabelByMatch('Zammad Foundation', 'Foundation')).toEqual({
      before: 'Zammad ',
      matched: 'Foundation',
      after: '',
    })
  })

  it('matches case-insensitively', () => {
    expect(splitLabelByMatch('Zammad Foundation', 'zammad')).toEqual({
      before: '',
      matched: 'Zammad',
      after: ' Foundation',
    })
  })

  it('matches an unaccented keyword against accented text and keeps the accents', () => {
    expect(splitLabelByMatch('Cafe\u0301 Zammad', 'cafe')).toEqual({
      before: '',
      matched: 'Cafe\u0301',
      after: ' Zammad',
    })
  })

  it('keeps the offset correct after a combining mark', () => {
    expect(splitLabelByMatch('Cafe\u0301 Zammad', 'zammad')).toEqual({
      before: 'Cafe\u0301 ',
      matched: 'Zammad',
      after: '',
    })
  })

  it('keeps the offset correct after several combining marks', () => {
    expect(splitLabelByMatch('E\u0301milie Mu\u0308ller Zammad', 'zammad')).toEqual({
      before: 'E\u0301milie Mu\u0308ller ',
      matched: 'Zammad',
      after: '',
    })
  })

  it('treats the keyword as literal text rather than a pattern', () => {
    expect(splitLabelByMatch('Costs (net)', '(net)')).toEqual({
      before: 'Costs ',
      matched: '(net)',
      after: '',
    })
  })
})
