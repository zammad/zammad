// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { generateFingerprint } from '../browser.ts'

vi.hoisted(() => {
  const userAgentSpy = vi.spyOn(window.navigator, 'userAgent', 'get')
  userAgentSpy.mockReturnValue(
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4758.102 Safari/537.36',
  )
})

describe('browser', () => {
  it('generate fingerprint', () => {
    expect(generateFingerprint()).toBe('91006247')
  })
})
