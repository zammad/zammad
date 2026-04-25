// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { KnowledgeBaseAnswerTranslation } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

const path = (metaObject: KnowledgeBaseAnswerTranslation) => {
  const answerId = getIdFromGraphQLId(metaObject.answer.id)
  return `#knowledge_base/1/locale/${metaObject.kbLocale.systemLocale.locale}/answer/${answerId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject?: KnowledgeBaseAnswerTranslation,
): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the knowledge base answer.')
  }

  const objectTitle = metaObject.title || '-'

  switch (type) {
    case 'create':
      return i18n.t('Knowledge Base Answer "|%s|" has been created', objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  path,
  messageText,
  model: 'KnowledgeBase::Answer::Translation',
}
