// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import type { FormUpdaterQuery } from '#shared/graphql/types.ts'

import { mockGraphQLApi } from '../mock-graphql-api.ts'

export const mockFormUpdater = (formUpdater?: FormUpdaterQuery) => {
  return mockGraphQLApi(FormUpdaterDocument).willResolve(
    formUpdater || {
      formUpdater: {},
    },
  )
}
