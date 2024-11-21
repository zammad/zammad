// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { User } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

const path = (metaObject: User) => {
  return `users/${metaObject.internalId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject?: User,
): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the user.')
  }

  const objectTitle = metaObject.fullname || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created user |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated user |%s|', authorName, objectTitle)
    case 'session started':
      return i18n.t('%s started a new session', authorName)
    case 'switch to':
      return i18n.t('%s switched to |%s|!', authorName, objectTitle)
    case 'ended switch to':
      return i18n.t('%s ended switch to |%s|!', authorName, objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'User',
}
