// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumKnowledgeBaseVisibility,
  KnowledgeBaseCategory,
} from '#shared/graphql/schema-types.ts'
import type {
  KnowledgeBaseAnswerQuery,
  KnowledgeBaseCategoryPolicyFragment,
  KnowledgeBaseSearchQuery,
} from '#shared/graphql/types.ts'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import type { KnowledgeBaseIconSet } from '#desktop/entities/knowledge-base/types.ts'

export interface KnowledgeBaseLocaleCompact {
  id: string
  primary: boolean
  systemLocale: {
    id: string
    locale: string
    name: string
  }
}

export interface KnowledgeBaseCompact {
  id: string
  title: string | null | undefined
  iconset: string
  isPubliclyAvailable: boolean
  isVisiblePublicly: boolean
  kbLocales: KnowledgeBaseLocaleCompact[]
}

export interface KnowledgeBaseCategoryCompact {
  id: string
  title: string | null | undefined
  categoryIcon: string
  visibility: EnumKnowledgeBaseVisibility
  translationMissing: boolean
  answerCount: number
  subcategoryCount: number
  position: number
  isDeletable: boolean
  // Per-record permissions, which granular setups can narrow below the global editor
  //   permission — the card offers its actions by these, not by the global one. Taken from
  //   the fragment every category selection shares, so it cannot drift from what is fetched.
  policy: KnowledgeBaseCategoryPolicyFragment['policy']
}

// What the category flyout needs to edit a category: the id addresses it, the other
//   two prefill the fields the form updater does not resolve. Spelled out rather than
//   picked from one of the two sources that satisfy it — the browse cards and the
//   header breadcrumb differ on how optional the title is.
export interface EditableKnowledgeBaseCategory {
  id: string
  title?: Maybe<string>
  categoryIcon: string
}

export interface KnowledgeBaseAnswerCompact {
  id: string
  visibility: EnumKnowledgeBaseVisibility
  translationMissing: boolean
  position: number
  title?: string | null
}

export type CategoryBreadcrumb = Pick<
  KnowledgeBaseCategory,
  'id' | 'title' | 'categoryIcon' | 'iconSet' | 'visibility'
>[]

// Derived from the query document, so the answer header cannot drift from what
//   it actually fetches.
export type KnowledgeBaseAnswerHeader = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>

// One search hit as the result list receives it — likewise derived from the query document.
export type KnowledgeBaseSearchResult =
  KnowledgeBaseSearchQuery['knowledgeBaseSearch']['edges'][number]['node']

export type KnowledgeBaseBreadcrumbItem = BreadcrumbItem & {
  iconSet?: KnowledgeBaseIconSet
  visibility?: EnumKnowledgeBaseVisibility
}
