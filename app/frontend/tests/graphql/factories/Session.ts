// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Session } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<Session> => {
  return {
    id: '6605e8986992bf38b8a03638a5c6090e',
    afterAuth: null,
  }
}
