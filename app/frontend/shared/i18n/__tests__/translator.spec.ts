// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { Translator } from '../translator'

describe('Translator', () => {
  const t = new Translator()
  it('starts with empty state', () => {
    expect(t.translate('unknown string')).toBe('unknown string')
    expect(t.translate('yes')).toBe('yes')
  })

  it('keeps unknown strings', () => {
    const map = new Map([
      ['yes', 'ja'],
      [
        'String with 3 placeholders: %s %s %s',
        'Zeichenkette mit 3 Platzhaltern: %s %s %s',
      ],
    ])

    t.setTranslationMap(map)

    expect(t.translate('unknown string')).toBe('unknown string')
    expect(t.translate('unknown string with placeholder %s')).toBe(
      'unknown string with placeholder %s',
    )
  })
  it('translates known strings', () => {
    expect(t.translate('yes')).toBe('ja')
  })
  it('handles placeholders correctly', () => {
    // No arguments.
    expect(t.translate('String with 3 placeholders: %s %s %s')).toBe(
      'Zeichenkette mit 3 Platzhaltern: %s %s %s',
    )
    // Partial arguments.
    expect(t.translate('String with 3 placeholders: %s %s %s', 1, '2')).toBe(
      'Zeichenkette mit 3 Platzhaltern: 1 2 %s',
    )
    // Correct arguments.
    expect(
      t.translate('String with 3 placeholders: %s %s %s', 1, '2', 'some words'),
    ).toBe('Zeichenkette mit 3 Platzhaltern: 1 2 some words')
    // Excess arguments.
    expect(
      t.translate(
        'String with 3 placeholders: %s %s %s',
        1,
        '2',
        'some words',
        3,
        4,
      ),
    ).toBe('Zeichenkette mit 3 Platzhaltern: 1 2 some words')
  })
  it('lookup() works correctly', () => {
    expect(t.lookup('yes')).toBe('ja')
    expect(t.lookup('NONEXISTING')).toBe(undefined)
  })
})
