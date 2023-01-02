// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { User } from '@shared/graphql/types'
import type { ActivityMessageBuilder } from '../types'

const path = (metaObject: User) => {
  return `users/${metaObject.internalId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject: User,
): Maybe<string> => {
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
