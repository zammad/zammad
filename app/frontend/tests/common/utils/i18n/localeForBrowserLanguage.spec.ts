// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import localeForBrowserLanguage from '@common/utils/i18n/localeForBrowserLanguage'
import { TextDirection } from '@common/graphql/types'

describe('localeFinder', () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let windowSpy: any

  beforeEach(() => {
    windowSpy = jest.spyOn(window.navigator, 'languages', 'get')
  })

  afterEach(() => {
    windowSpy.mockRestore()
  })

  const locales = [
    {
      active: true,
      alias: 'de',
      dir: TextDirection.Ltr,
      locale: 'de-de',
      name: 'Deutsch',
    },
    {
      active: true,
      alias: 'es',
      dir: TextDirection.Ltr,
      locale: 'es-es',
      name: 'Español',
    },
    {
      active: true,
      alias: '',
      dir: TextDirection.Ltr,
      locale: 'es-co',
      name: 'Español (Colombia)',
    },
  ]

  it('returns correct locale for direct match', () => {
    windowSpy.mockImplementation(() => ['es-CO'])
    expect(localeForBrowserLanguage(locales)).toStrictEqual(locales[2])
  })

  it('returns correct locale for alias match', () => {
    windowSpy.mockImplementation(() => ['es-MX'])
    expect(localeForBrowserLanguage(locales)).toStrictEqual(locales[1])
  })

  it('returns default locale for no match', () => {
    windowSpy.mockImplementation(() => ['sv-SV'])
    expect(localeForBrowserLanguage(locales)).toStrictEqual({
      active: true,
      alias: 'en',
      dir: TextDirection.Ltr,
      locale: 'en-us',
      name: 'English (United States)',
    })
  })
})
