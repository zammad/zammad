// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useThirdPartyAuthentication } from '../authentication/useThirdPartyAuthentication.ts'

vi.mock('#shared/utils/browser.ts', () => {
  return {
    generateFingerprint: vi.fn().mockReturnValue('foo'),
  }
})

vi.mock('#shared/router/router.ts', () => ({
  getCurrentRouter: vi.fn().mockReturnValue({
    currentRoute: {
      value: {
        query: {
          redirect: '/bar',
        },
      },
    },
  }),
}))

describe('useThirdPartyAuthentication', () => {
  beforeEach(() => {
    mockApplicationConfig({
      auth_github: true,
      auth_gitlab: true,
      auth_saml: true,
    })
  })

  it('constructs provider URLs with fingerprint and redirect query parameters', () => {
    const { enabledProviders, hasEnabledProviders } = useThirdPartyAuthentication()

    expect(enabledProviders.value).toHaveLength(3)
    expect(hasEnabledProviders.value).toBe(true)

    enabledProviders.value.forEach((provider) => {
      expect(provider.url).toContain(`/auth/${provider.name}?fingerprint=foo&redirect=%2Fbar`)
    })
  })
})
