// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import localeForBrowserLanguage from '@common/utils/i18n/localeForBrowserLanguage'

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
    { active: true, alias: 'de', dir: 'ltr', locale: 'de-de', name: 'Deutsch' },
    { active: true, alias: 'es', dir: 'ltr', locale: 'es-es', name: 'Español' },
    {
      active: true,
      alias: '',
      dir: 'ltr',
      locale: 'es-co',
      name: 'Español (Colombia)',
    },
  ]

  it('returns correct locale for direct match', () => {
    windowSpy.mockImplementation(() => ['es-CO'])
    expect(localeForBrowserLanguage(locales)).toBe('es-co')
  })

  it('returns correct locale for alias match', () => {
    windowSpy.mockImplementation(() => ['es-MX'])
    expect(localeForBrowserLanguage(locales)).toBe('es-es')
  })

  it('returns default locale for no match', () => {
    windowSpy.mockImplementation(() => ['sv-SV'])
    expect(localeForBrowserLanguage(locales)).toBe('en-us')
  })
})
