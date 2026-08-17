// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { Link } from '#shared/types/router.ts'

import { knowledgeBaseAnswerRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { RelatedAnswer } from '../types.ts'

// The answer page of the public help site.
// NB: A custom address (an alternative, prettier mount point of the help site) is not applied here -
//   the canonical `/help` path stays available in that case as well.
const publicAnswerLink = (translation: RelatedAnswer['translation']) => {
  const { locale } = translation.kbLocale.systemLocale
  const categoryId = getIdFromGraphQLId(translation.answer.category.id)
  const answerId = getIdFromGraphQLId(translation.answer.id)

  return `/help/${locale}/${categoryId}/${answerId}`
}

// Where a knowledge base answer of the ticket sidebar (linked or AI suggested) takes the user.
//
// Agents without knowledge base permission cannot open the answer view of the agent interface, so
//   they are sent to the public answer page instead. They are only ever offered published answers
//   (the backend scopes both the link list and the search), which that page shows.
export const getKnowledgeBaseAnswerLink = (translation: RelatedAnswer['translation']): Link => {
  if (!useSessionStore().hasPermission('knowledge_base.*')) return publicAnswerLink(translation)

  const { locale } = translation.kbLocale.systemLocale

  return knowledgeBaseAnswerRoute(locale, translation.answer.id)
}
