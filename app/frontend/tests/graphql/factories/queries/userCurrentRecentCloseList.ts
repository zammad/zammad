// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { UserCurrentRecentCloseListQuery } from '#shared/graphql/types.ts'

export default (): UserCurrentRecentCloseListQuery => {
  return {
    userCurrentRecentCloseList: [],
  }
}
