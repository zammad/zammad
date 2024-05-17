// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import { createMockClient } from 'mock-apollo-client'
import { createPinia, setActivePinia } from 'pinia'

import { LocalesDocument } from '#shared/graphql/queries/locales.api.ts'
import type { LocalesQuery } from '#shared/graphql/types.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

import { useLocaleStore } from '../locale.ts'

const mockQueryResult = (): LocalesQuery => {
  return {
    locales: [
      {
        locale: 'de-de',
        name: 'Deutsch',
        dir: EnumTextDirection.Ltr,
        alias: 'de',
        active: true,
      },
      {
        locale: 'ar',
        name: 'Arabic',
        dir: EnumTextDirection.Rtl,
        alias: null,
        active: true,
      },
    ],
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(LocalesDocument, () => {
    return Promise.resolve({ data: mockQueryResult() })
  })
  provideApolloClient(mockApolloClient)
}

describe('Translations Store', () => {
  setActivePinia(createPinia())
  mockClient()
  const locale = useLocaleStore()

  it('is empty by default', () => {
    expect(locale.localeData).toBe(null)
  })

  it('sets rtl correctly', async () => {
    expect.assertions(4)
    await locale.setLocale('ar')
    expect(document.documentElement.getAttribute('dir')).toBe('rtl')
    expect(document.documentElement.getAttribute('lang')).toBe('ar')
    await locale.setLocale('de-de')
    expect(document.documentElement.getAttribute('dir')).toBe('ltr')
    expect(document.documentElement.getAttribute('lang')).toBe('de-de')
  })
})
