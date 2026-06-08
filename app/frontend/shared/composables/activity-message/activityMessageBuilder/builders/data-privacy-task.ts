// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { DataPrivacyTask } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

const path = (_metaObject: DataPrivacyTask) => '#'

const messageText = (
  type: string,
  authorName: string,
  metaObject?: DataPrivacyTask,
): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the data privacy task.')
  }

  const objectTitle = metaObject.deletableId || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created data privacy task to delete user ID |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated data privacy task to delete user ID |%s|', authorName, objectTitle)
    case 'completed':
      return i18n.t(
        '%s completed data privacy task to delete user ID |%s|',
        authorName,
        objectTitle,
      )
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'DataPrivacyTask',
}
