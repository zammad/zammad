// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import apolloClient from '@common/server/apollo/client'
import { QueryHandler } from '@common/server/apollo/handler'
import { useLocalesQuery } from '@common/graphql/api'
import { LocalesQuery } from '@common/graphql/types'

let availableLocales: Maybe<LocalesQuery['locales']>

const getAvailableLocales = async (): Promise<
  Maybe<LocalesQuery['locales']>
> => {
  if (availableLocales !== undefined) return availableLocales

  provideApolloClient(apolloClient)

  const query = new QueryHandler(useLocalesQuery())
  const result = await query.loadedResult()

  availableLocales = result?.locales || null

  return availableLocales
}

export default getAvailableLocales
