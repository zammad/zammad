// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { LocalesQuery } from '@common/graphql/types'

export default function localeForBrowserLanguage(
  locales: LocalesQuery['locales'],
): string {
  const userLanguages = window.navigator.languages || [
    window.navigator.language,
  ]

  for (const userLanguage of userLanguages.values()) {
    const directMatch = locales.find((elem) => {
      return userLanguage.toLowerCase() === elem.locale
    })
    if (directMatch) return directMatch.locale
    const alias = userLanguage.substr(0, 2).toLowerCase()
    const aliasMatch = locales.find((elem) => {
      return alias === elem.alias
    })
    if (aliasMatch) return aliasMatch.locale
  }

  return 'en-us'
}
