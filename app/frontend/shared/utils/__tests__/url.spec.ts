// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { safeUrl } from '#shared/utils/url.ts'

describe('safeUrl', () => {
  it.each([
    'https://example.com',
    'http://example.com',
    'mailto:test@example.com',
    'tel:+1234567890',
    '/relative/path',
    '#anchor',
    'data:image/png;base64,',
    'blob:https://example.com/1234',
    '',
  ])('keeps safe url %s', (url) => {
    expect(safeUrl(url)).toBe(url)
  })

  it.each([
    'javascript:alert(1)',
    'vbscript:msgbox(1)',
    'JavaScript:alert(1)',

    'java\tscript:alert(1)',

    'java\nscript:alert(1)',
  ])('drops script-executing url %j', (url) => {
    expect(safeUrl(url)).toBe('')
  })

  it('returns empty string for nullish input', () => {
    expect(safeUrl(undefined)).toBe('')
    expect(safeUrl(null)).toBe('')
  })
})
