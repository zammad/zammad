// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { LocalesQuery, TextDirection } from '@common/graphql/types'
import type { LastArrayElement } from 'type-fest'

export default function localeForBrowserLanguage(
  locales: LocalesQuery['locales'],
): LastArrayElement<LocalesQuery['locales']> {
  const userLanguages = window.navigator.languages || [
    window.navigator.language,
  ]

  for (const userLanguage of userLanguages.values()) {
    const directMatch = locales.find((elem) => {
      return userLanguage.toLowerCase() === elem.locale
    })
    if (directMatch) return directMatch
    const alias = userLanguage.substr(0, 2).toLowerCase()
    const aliasMatch = locales.find((elem) => {
      return alias === elem.alias
    })
    if (aliasMatch) return aliasMatch
  }

  return {
    locale: 'en-us',
    alias: 'en',
    // eslint-disable-next-line zammad/zammad-detect-translatable-string
    name: 'English (United States)',
    dir: TextDirection.Ltr,
    active: true,
  }
}
