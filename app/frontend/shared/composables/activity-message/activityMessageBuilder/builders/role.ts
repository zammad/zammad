// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { DataPrivacyTask, Role } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

const path = (_metaObject: DataPrivacyTask) => '#'

const messageText = (type: string, authorName: string, metaObject?: Role): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the role.')
  }

  const objectTitle = metaObject.name || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created role |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated role |%s|', authorName, objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'Role',
}
