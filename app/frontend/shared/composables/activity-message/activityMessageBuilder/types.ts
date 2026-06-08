// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ActivityMessageMetaObject } from '#shared/graphql/types.ts'

export interface ActivityMessageBuilder {
  model: string
  path: (metaObject: ActivityMessageMetaObject) => string | undefined
  messageText: (
    type: string,
    authorName: string,
    metaObject?: Maybe<ActivityMessageMetaObject>,
  ) => string
}
