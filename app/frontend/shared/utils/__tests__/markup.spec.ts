// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { cleanupMarkup, markup } from '../markup.ts'

describe('markup()', () => {
  it('returns correct html', () => {
    expect(markup('||italic||')).toBe('<i>italic</i>')
    expect(markup('|bold|')).toBe('<b>bold</b>')
    expect(markup('_underline_')).toBe('<u>underline</u>')
    expect(markup('//strikethrough//')).toBe('<del>strikethrough</del>')
    expect(markup('§keyboard§')).toBe('<kbd>keyboard</kbd>')
    expect(markup('[link](https://zammad.org)')).toBe(
      '<a href="https://zammad.org" target="_blank">link</a>',
    )
  })

  it('escapes passed value', () => {
    expect(markup('§<kbd>key</kbd>§')).toBe('<kbd>&lt;kbd&gt;key&lt;/kbd&gt;</kbd>')
  })
})

describe('cleanupMarkup()', () => {
  it('removes markup', () => {
    expect(cleanupMarkup('||italic||')).toBe('italic')
    expect(cleanupMarkup('|bold|')).toBe('bold')
    expect(cleanupMarkup('_underline_')).toBe('underline')
    expect(cleanupMarkup('//strikethrough//')).toBe('strikethrough')
    expect(cleanupMarkup('§keyboard§')).toBe('keyboard')
    expect(cleanupMarkup('[link](https://zammad.org)')).toBe('link')
  })
})
