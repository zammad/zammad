// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { Organization } from '@shared/graphql/types'
import type { ActivityMessageBuilder } from '../types'

const path = (metaObject: Organization) => {
  return `organizations/${metaObject.internalId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject: Organization,
): Maybe<string> => {
  const objectTitle = metaObject.name || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created organization |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated organization |%s|', authorName, objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  path,
  messageText,
  model: 'Organization',
}
