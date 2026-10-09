// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isAppleWebKit } from '../webPush.ts'

describe('isAppleWebKit', () => {
  it.each([
    [
      'Safari on an iPhone',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1',
    ],
    [
      'an app on the home screen of an iPhone',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
    ],
    [
      'Safari on an iPad, which reports a Mac',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15',
    ],
  ])('is true for %s', (_description, userAgent) => {
    expect(isAppleWebKit(userAgent)).toBe(true)
  })

  it.each([
    [
      'Chrome on Android',
      'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
    ],
    [
      'Chrome on a desktop',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
    ],
    [
      'Edge',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0',
    ],
    ['Firefox', 'Mozilla/5.0 (Android 15; Mobile; rv:143.0) Gecko/143.0 Firefox/143.0'],
  ])('is false for %s', (_description, userAgent) => {
    expect(isAppleWebKit(userAgent)).toBe(false)
  })
})
