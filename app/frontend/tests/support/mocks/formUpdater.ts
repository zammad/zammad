// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormUpdaterDocument } from '@shared/components/Form/graphql/queries/formUpdater.api'
import type { FormUpdaterQuery } from '@shared/graphql/types'
import { mockGraphQLApi } from '../mock-graphql-api'

export const mockFormUpdater = (formUpdater?: FormUpdaterQuery) => {
  return mockGraphQLApi(FormUpdaterDocument).willResolve(
    formUpdater || {
      formUpdater: {},
    },
  )
}
