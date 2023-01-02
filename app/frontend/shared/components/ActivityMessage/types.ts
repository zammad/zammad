// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ActivityMessageMetaObject } from '@shared/graphql/types'

export interface ActivityMessageBuilder {
  model: string
  path: (metaObject: ActivityMessageMetaObject) => string
  messageText: (
    type: string,
    authorName: string,
    metaObject: ActivityMessageMetaObject,
  ) => string
}
