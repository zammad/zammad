// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { QueryHandler } from '@shared/server/apollo/handler'
import { useLocalesQuery } from '@shared/graphql/queries/locales.api'
import type { LocalesQuery } from '@shared/graphql/types'

let availableLocales: Maybe<LocalesQuery['locales']>

const getAvailableLocales = async (): Promise<
  Maybe<LocalesQuery['locales']>
> => {
  if (availableLocales !== undefined) return availableLocales

  const query = new QueryHandler(useLocalesQuery({ onlyActive: true }))
  const result = await query.loadedResult()

  availableLocales = result?.locales || null

  return availableLocales
}

export default getAvailableLocales
