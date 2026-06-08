// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { DataPrivacyTask, Group } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

const path = (_metaObject: DataPrivacyTask) => '#'

const messageText = (
  messageType: string,
  authorName: string,
  metaObject?: Group,
): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the group.')
  }

  const objectTitle = metaObject.name || '-'

  switch (messageType) {
    case 'create':
      return i18n.t('%s created group |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated group |%s|', authorName, objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'Group',
}
