// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import { LocalesDocument } from '@shared/graphql/queries/locales.api'
import { LocalesQuery, TextDirection } from '@shared/graphql/types'
import useLocaleStore from '../locale'

const mockQueryResult = (): LocalesQuery => {
  return {
    locales: [
      {
        locale: 'de-de',
        name: 'Deutsch',
        dir: TextDirection.Ltr,
        alias: 'de',
        active: true,
      },
      {
        locale: 'ar',
        name: 'Arabic',
        dir: TextDirection.Rtl,
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
    await locale.updateLocale('ar')
    expect(document.documentElement.getAttribute('dir')).toBe('rtl')
    expect(document.documentElement.getAttribute('lang')).toBe('ar')
    await locale.updateLocale('de-de')
    expect(document.documentElement.getAttribute('dir')).toBe('ltr')
    expect(document.documentElement.getAttribute('lang')).toBe('de-de')
  })
})
