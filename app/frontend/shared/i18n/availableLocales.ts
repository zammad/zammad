// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { QueryHandler } from '@shared/server/apollo/handler'
import { useLocalesLazyQuery } from '@shared/graphql/queries/locales.api'
import type { LocalesQuery } from '@shared/graphql/types'

let availableLocales: Maybe<LocalesQuery['locales']>

const getAvailableLocales = async (): Promise<
  Maybe<LocalesQuery['locales']>
> => {
  if (availableLocales !== undefined) return availableLocales

  const query = new QueryHandler(useLocalesLazyQuery({ onlyActive: true }))
  const { data: result } = await query.query()

  availableLocales = result?.locales || null

  return availableLocales
}

export default getAvailableLocales
