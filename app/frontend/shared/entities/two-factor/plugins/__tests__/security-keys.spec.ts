// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// We have this unit test case because we currently don't run E2E tests for HTTPS methods.
// If we start doing that, we can remove this test case.

import { get } from '@github/webauthn-json'

import securityKeys from '../security-keys.ts'

vi.mock('@github/webauthn-json', () => ({ get: vi.fn() }))

const webauthnMock = vi.mocked(get, { partial: true })

describe('security keys method correctly handles setup', () => {
  beforeEach(() => {
    vi.stubGlobal('isSecureContext', true)
  })

  it('returns an error if running inside insecure context', async () => {
    vi.stubGlobal('isSecureContext', false)

    const result = await securityKeys.loginOptions.setup({ challenge: '123' })
    expect(result.success).toBe(false)
    expect(result.retry, 'cannot retry, since it always returns false').toBe(
      false,
    )
    expect(result.error, 'has error').toEqual(expect.any(String))
  })

  it('returns generic error, if webauthn failed', async () => {
    webauthnMock.mockRejectedValue(new Error('webauthn failed'))

    const result = await securityKeys.loginOptions.setup({ challenge: '123' })
    expect(result.success).toBe(false)
    expect(result.retry).toBe(true)
    expect(result.error, 'has error').toEqual(expect.any(String))
  })

  it('returns payload, if webauthn succeeded', async () => {
    const credential = { credential: '123' }
    webauthnMock.mockResolvedValue(credential as any)

    const result = await securityKeys.loginOptions.setup({ challenge: '123' })
    expect(result.success).toBe(true)
    expect(result.payload).toEqual({
      challenge: '123',
      credential,
    })
    expect(result.retry).toBeUndefined()
    expect(result.error).toBeUndefined()
  })
})
