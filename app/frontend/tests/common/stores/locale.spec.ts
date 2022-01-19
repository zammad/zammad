// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useLocaleStore from '@common/stores/locale'
import { createTestingPinia } from '@pinia/testing'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import { LocalesDocument } from '@common/graphql/api'
import { LocalesQuery, TextDirection } from '@common/graphql/types'

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
  createTestingPinia()
  mockClient()
  const locale = useLocaleStore()

  it('is empty by default', () => {
    expect(locale.value).toBe(null)
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
