// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import type { RelatedAnswer } from '../types.ts'

export const getKnowledgeBaseAnswerLink = (translation: RelatedAnswer['translation']) => {
  const knowledgeBaseId = getIdFromGraphQLId(translation.answer.category.knowledgeBase.id)
  const { locale } = translation.kbLocale.systemLocale
  const answerId = getIdFromGraphQLId(translation.answer.id)

  return `/#knowledge_base/${knowledgeBaseId}/locale/${locale}/answer/${answerId}`
}
