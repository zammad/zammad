// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { Group } from '@shared/graphql/types'
import type { ActivityMessageBuilder } from '../types'

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const path = (metaObject: Group) => {
  return '#'
}

const messageText = (
  messageType: string,
  authorName: string,
  metaObject: Group,
): Maybe<string> => {
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
