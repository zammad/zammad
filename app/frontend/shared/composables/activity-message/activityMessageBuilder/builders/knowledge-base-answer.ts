// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useAppName } from '#shared/composables/useAppName.ts'
import type { KnowledgeBaseAnswerTranslation } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { ActivityMessageBuilder } from '../types.ts'

// Agents without knowledge base permission cannot open the answer view of the desktop app, so
//   they are sent to the public answer page instead - same split as the ticket sidebar's answer
//   links (see knowledgeBaseAnswerLink.ts). Relative, app-prefix-free paths (matching
//   ticket.ts/user.ts/organization.ts in this same folder): each app's notification list prefixes
//   them with a slash.
const path = (metaObject: KnowledgeBaseAnswerTranslation) => {
  const answerId = getIdFromGraphQLId(metaObject.answer.id)
  const { locale } = metaObject.kbLocale.systemLocale

  if (!useSessionStore().hasPermission('knowledge_base.*')) {
    const categoryId = getIdFromGraphQLId(metaObject.answer.category.id)
    return `help/${locale}/${categoryId}/${answerId}`
  }

  const answerPath = `knowledge-base/locale/${locale}/answer/${answerId}`

  // The answer view exists in the desktop app only. Linking there is safe, as the desktop app
  //   never redirects back to mobile - unlike the old app, which would bounce mobile devices.
  return useAppName() === 'mobile' ? `desktop/${answerPath}` : answerPath
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
