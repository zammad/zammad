// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useTranslationsStore from '@common/stores/translations'
import { i18n } from '@common/utils/i18n'
import { createTestingPinia } from '@pinia/testing'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import { TranslationsDocument } from '@common/graphql/api'
import { TranslationsPayload } from '@common/graphql/types'

const mockQueryResult = (
  locale: string,
  cacheKey: string | null,
): TranslationsPayload => {
  if (cacheKey === 'MOCKED_CACHE_KEY') {
    return {
      isCacheStillValid: true,
      cacheKey,
      translations: {},
    }
  }
  if (locale === 'de-de') {
    return {
      isCacheStillValid: false,
      cacheKey: 'MOCKED_CACHE_KEY',
      translations: {
        Login: 'Anmeldung',
      },
    }
  }
  return {
    isCacheStillValid: false,
    cacheKey: 'MOCKED_CACHE_KEY',
    translations: {
      Login: 'Login (translated)',
    },
  }
}

let lastQueryResult: TranslationsPayload

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(TranslationsDocument, (variables) => {
    lastQueryResult = mockQueryResult(variables.locale, variables.cacheKey)
    return Promise.resolve({ data: { translations: lastQueryResult } })
  })

  provideApolloClient(mockApolloClient)
}

describe('Translations Store', () => {
  createTestingPinia()
  const translations = useTranslationsStore()
  mockClient()

  it('is empty by default', () => {
    expect(translations.value).toStrictEqual({
      cacheKey: 'CACHE_EMPTY',
      translations: {},
    })
    expect(i18n.t('Login')).toBe('Login')
  })

  it('loads translations without cache', async () => {
    expect.assertions(4)
    await translations.load('de-de')
    expect(lastQueryResult.isCacheStillValid).toBe(false)
    expect(translations.value.cacheKey.length).toBeGreaterThan(5)
    expect(translations.value.translations).toHaveProperty('Login', 'Anmeldung')
    expect(i18n.t('Login')).toBe('Anmeldung')
  })

  it('switch to en-us translations', async () => {
    expect.assertions(3)
    await translations.load('en-us')
    expect(lastQueryResult.isCacheStillValid).toBe(false)
    expect(translations.value.cacheKey.length).toBeGreaterThan(5)
    expect(translations.value.translations).toHaveProperty(
      'Login',
      'Login (translated)',
    )
  })

  it('loads translations from a warm cache', async () => {
    expect.assertions(5)
    await translations.load('de-de')
    expect(lastQueryResult.isCacheStillValid).toBe(true)
    expect(lastQueryResult.translations).toStrictEqual({})
    expect(translations.value.cacheKey.length).toBeGreaterThan(5)
    expect(translations.value.translations).toHaveProperty('Login', 'Anmeldung')
    expect(i18n.t('Login')).toBe('Anmeldung')
  })
})
