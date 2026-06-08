// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// We have this unit test case because we currently don't run E2E tests for HTTPS methods.
// If we start doing that, we can remove this test case.

import { mockWebAuthnAuthentication } from '#tests/support/mock-webauthn.ts'

import securityKeys from '../security-keys.ts'

describe('security keys method correctly handles setup', () => {
  // Mock public key in JSON format (as received from backend)
  const mockPublicKey = {
    challenge: '6bgWqBn8JO0RlXrqZ5HW2RPl2iFjXOKESPKSxzZJniI',
    timeout: 120000,
    extensions: {},
    allowCredentials: [
      {
        type: 'public-key',
        id: 'XDYDtlpC1MtSJ2Y-85YjslY1W7I',
      },
    ],
    userVerification: 'discouraged',
  }

  let getSpy: ReturnType<typeof vi.fn>
  let parseRequestOptionsFromJSONSpy: ReturnType<typeof vi.fn>

  beforeEach(() => {
    ;({ getSpy, parseRequestOptionsFromJSONSpy } = mockWebAuthnAuthentication())
  })

  it('returns an error if running inside insecure context', async () => {
    vi.stubGlobal('isSecureContext', false)

    const result = await securityKeys.loginOptions.setup(mockPublicKey)
    expect(result.success).toBe(false)
    expect(result.retry, 'cannot retry, since it always returns false').toBe(false)
    expect(result.error, 'has error').toEqual(expect.any(String))
  })

  it('returns generic error, if webauthn failed', async () => {
    parseRequestOptionsFromJSONSpy.mockReturnValue({
      challenge: new Uint8Array(32),
      timeout: 120000,
      extensions: {},
      allowCredentials: [],
      userVerification: 'discouraged',
    })
    getSpy.mockRejectedValue(new Error('webauthn failed'))

    const result = await securityKeys.loginOptions.setup(mockPublicKey)
    expect(result.success).toBe(false)
    expect(result.retry).toBe(true)
    expect(result.error, 'has error').toEqual(expect.any(String))
  })

  it('returns payload, if webauthn succeeded', async () => {
    // Mock the parsed public key options (after parsing JSON)
    const mockParsedPublicKey = {
      challenge: new Uint8Array(32), // This represents the decoded challenge
      timeout: 120000,
      extensions: {},
      allowCredentials: [
        {
          type: 'public-key' as const,
          id: new Uint8Array(16),
        },
      ],
      userVerification: 'discouraged' as const,
    }
    parseRequestOptionsFromJSONSpy.mockReturnValue(mockParsedPublicKey)

    const result = await securityKeys.loginOptions.setup(mockPublicKey)

    expect(parseRequestOptionsFromJSONSpy).toHaveBeenCalledWith(mockPublicKey)
    expect(getSpy).toHaveBeenCalledWith({
      publicKey: mockParsedPublicKey,
    })
    expect(result.success).toBe(true)
    expect(result.payload).toEqual({
      challenge: expect.any(String),
      credential: expect.objectContaining({
        id: 'credential-id',
        type: 'public-key',
      }),
    })
    expect(result.retry).toBeUndefined()
    expect(result.error).toBeUndefined()
  })
})
