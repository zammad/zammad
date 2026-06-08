// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Mock WebAuthn credential for testing
 */
export const createMockCredential = (overrides?: Partial<PublicKeyCredential>) => {
  const defaultCredential = {
    id: 'credential-id',
    type: 'public-key' as const,
    rawId: new ArrayBuffer(16),
    response: {
      clientDataJSON: new ArrayBuffer(32),
      attestationObject: new ArrayBuffer(64),
    },
    toJSON: vi.fn().mockReturnValue({
      id: 'credential-id',
      type: 'public-key',
      rawId: 'mock-raw-id',
      response: {
        clientDataJSON: 'mock-client-data',
        attestationObject: 'mock-attestation',
      },
    }),
  }

  return { ...defaultCredential, ...overrides }
}

/**
 * Mock parsed creation options returned by parseCreationOptionsFromJSON
 */
export const createMockCreationOptions = (
  overrides?: Partial<PublicKeyCredentialCreationOptions>,
): PublicKeyCredentialCreationOptions => {
  const defaultOptions: PublicKeyCredentialCreationOptions = {
    challenge: new Uint8Array(32),
    rp: { name: 'Zammad', id: 'localhost' },
    user: {
      id: new Uint8Array(16),
      name: 'user@example.com',
      displayName: 'Test User',
    },
    pubKeyCredParams: [{ type: 'public-key', alg: -7 }],
    timeout: 120000,
    attestation: 'none',
  }

  return { ...defaultOptions, ...overrides }
}

/**
 * Mock parsed request options returned by parseRequestOptionsFromJSON
 */
export const createMockRequestOptions = (
  overrides?: Partial<PublicKeyCredentialRequestOptions>,
): PublicKeyCredentialRequestOptions => {
  const defaultOptions: PublicKeyCredentialRequestOptions = {
    challenge: new Uint8Array(32),
    timeout: 120000,
    extensions: {},
    allowCredentials: [
      {
        type: 'public-key',
        id: new Uint8Array(16),
      },
    ],
    userVerification: 'discouraged',
  }

  return { ...defaultOptions, ...overrides }
}

/**
 * Setup WebAuthn mocks for credential creation (registration)
 */
export const mockWebAuthnCreation = (
  createMock?: ReturnType<typeof vi.fn>,
  parseCreationOptionsFromJSONMock?: ReturnType<typeof vi.fn>,
) => {
  const createFn = createMock || vi.fn()
  const parseFn = parseCreationOptionsFromJSONMock || vi.fn()

  vi.stubGlobal('isSecureContext', true)
  vi.stubGlobal('navigator', {
    credentials: {
      create: createFn,
    },
  })
  vi.stubGlobal('PublicKeyCredential', {
    parseCreationOptionsFromJSON: parseFn,
  })

  // Set default return values
  parseFn.mockReturnValue(createMockCreationOptions())
  createFn.mockResolvedValue(createMockCredential())

  return { createSpy: createFn, parseCreationOptionsFromJSONSpy: parseFn }
}

/**
 * Setup WebAuthn mocks for credential retrieval (authentication)
 */
export const mockWebAuthnAuthentication = (
  getMock?: ReturnType<typeof vi.fn>,
  parseRequestOptionsFromJSONMock?: ReturnType<typeof vi.fn>,
) => {
  const getFn = getMock || vi.fn()
  const parseFn = parseRequestOptionsFromJSONMock || vi.fn()

  vi.stubGlobal('isSecureContext', true)
  vi.stubGlobal('navigator', {
    credentials: {
      get: getFn,
    },
  })
  vi.stubGlobal('PublicKeyCredential', {
    parseRequestOptionsFromJSON: parseFn,
  })

  // Set default return values
  parseFn.mockReturnValue(createMockRequestOptions())
  getFn.mockResolvedValue({
    id: 'credential-id',
    type: 'public-key',
    rawId: new ArrayBuffer(16),
    response: {
      clientDataJSON: new ArrayBuffer(32),
      authenticatorData: new ArrayBuffer(64),
      signature: new ArrayBuffer(72),
      userHandle: null,
    },
    toJSON: vi.fn().mockReturnValue({
      id: 'credential-id',
      type: 'public-key',
      rawId: 'mock-raw-id',
      response: {
        clientDataJSON: 'mock-client-data',
        authenticatorData: 'mock-authenticator-data',
        signature: 'mock-signature',
        userHandle: null,
      },
    }),
  })

  return { getSpy: getFn, parseRequestOptionsFromJSONSpy: parseFn }
}
