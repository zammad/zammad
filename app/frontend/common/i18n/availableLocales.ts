// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { QueryHandler } from '@common/server/apollo/handler'
import { useLocalesQuery } from '@common/graphql/api'
import { LocalesQuery } from '@common/graphql/types'

let availableLocales: Maybe<LocalesQuery['locales']>

const getAvailableLocales = async (): Promise<
  Maybe<LocalesQuery['locales']>
> => {
  if (availableLocales !== undefined) return availableLocales

  const query = new QueryHandler(useLocalesQuery())
  const result = await query.loadedResult()

  availableLocales = result?.locales || null

  return availableLocales
}

export default getAvailableLocales
