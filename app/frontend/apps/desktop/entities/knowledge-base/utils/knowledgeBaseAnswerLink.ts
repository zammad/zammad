// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { Link } from '#shared/types/router.ts'

import { useKnowledgeBaseAccess } from '../composables/useKnowledgeBaseAccess.ts'

import { knowledgeBaseAnswerRoute } from './routeLocation.ts'

// Only what the link is actually built from, rather than one caller's fragment: the ticket
//   sidebar's suggestions and the quicksearch group arrive from different queries with different
//   selections, and both satisfy this structurally.
export interface KnowledgeBaseAnswerLinkTranslation {
  answer: {
    id: string
    category: {
      id: string
    }
  }
  kbLocale: {
    systemLocale: {
      locale: string
    }
  }
}

// The answer page of the public help site.
// NB: A custom address (an alternative, prettier mount point of the help site) is not applied here -
//   the canonical `/help` path stays available in that case as well.
const publicAnswerLink = (translation: KnowledgeBaseAnswerLinkTranslation) => {
  const { locale } = translation.kbLocale.systemLocale
  const categoryId = getIdFromGraphQLId(translation.answer.category.id)
  const answerId = getIdFromGraphQLId(translation.answer.id)

  return `/help/${locale}/${categoryId}/${answerId}`
}

// Where a knowledge base answer takes the user - from the ticket sidebar (linked or AI suggested)
//   and from the quicksearch results alike.
//
// Keyed on `canBrowse`, which is what the answer route's own guard is keyed on
//   (pages/knowledge-base/routes.ts: `requiredPermission: []`, `canAccess: canBrowse`). So anyone
//   who can open that route is sent there - a customer and an agent without any knowledge base
//   permission included, whenever the knowledge base is publicly available. They read the answer in
//   Zammad rather than being pushed out to the help site, and the popover's category row already
//   links into the knowledge base the same way.
//
// The public answer page stays the fallback for the one case that is left: no browsable knowledge
//   base at all, where the in-app route would refuse them. Nobody is ever offered an answer that is
//   not published (the backend scopes the link list, the suggestions and the search), and that page
//   shows exactly those.
export const getKnowledgeBaseAnswerLink = (
  translation: KnowledgeBaseAnswerLinkTranslation,
): Link => {
  if (!useKnowledgeBaseAccess().canBrowse.value) return publicAnswerLink(translation)

  const { locale } = translation.kbLocale.systemLocale

  return knowledgeBaseAnswerRoute(locale, translation.answer.id)
}
