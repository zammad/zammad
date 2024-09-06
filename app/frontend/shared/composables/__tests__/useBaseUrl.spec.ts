// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useBaseUrl } from '../useBaseUrl.ts'

describe('useBaseUrl', () => {
  it('returns configured base URL', () => {
    mockApplicationConfig({ http_type: 'https', fqdn: 'zammad.org' })

    const { baseUrl } = useBaseUrl()

    expect(baseUrl.value).toBe('https://zammad.org')
  })

  it('returns current base URL (zammad.example.com)', () => {
    mockApplicationConfig({ fqdn: 'zammad.example.com' })

    const { baseUrl } = useBaseUrl()

    expect(baseUrl.value).toBe('http://localhost:3000')
  })

  it('returns current base URL (empty FQDN)', () => {
    const { baseUrl } = useBaseUrl()

    expect(baseUrl.value).toBe('http://localhost:3000')
  })
})
