// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumKnowledgeBaseSortingMode,
  EnumKnowledgeBaseVisibility,
  KnowledgeBaseCategory,
  KnowledgeBaseCategoryTranslation,
} from '#shared/graphql/schema-types.ts'
import type {
  KnowledgeBaseAnswerQuery,
  KnowledgeBaseCategoryPolicyFragment,
  KnowledgeBaseSearchQuery,
} from '#shared/graphql/types.ts'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import type { KnowledgeBaseIconSet } from '#desktop/entities/knowledge-base/types.ts'

// The schema's own enum, built from KnowledgeBase::SORTING_MODES — so a mode the picker offers is
//   always one the reorder mutations accept. Aliased rather than used directly, because the
//   sorting state talks about a node's lists, not about the schema.
export type KnowledgeBaseSortingMode = EnumKnowledgeBaseSortingMode

// The two independently rearrangeable lists on a browse page. A category holds both, the
//   knowledge base root only categories. Each carries its own sorting mode, so an editor arranges
//   one of them at a time.
export type KnowledgeBaseSortingScope = 'categories' | 'answers'

// The modes a browsed node is stored with, one per list. The knowledge base root has no answers,
//   so it fills the `categories` entry alone.
export type KnowledgeBaseSortingModes = Partial<
  Record<KnowledgeBaseSortingScope, KnowledgeBaseSortingMode>
>

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
  title: string
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
//   picked from one of the two sources that satisfy it - the browse cards and the header
//   breadcrumb select different field sets around these three.
export interface EditableKnowledgeBaseCategory {
  id: string
  title: string
  categoryIcon: string
}

export interface KnowledgeBaseAnswerCompact {
  id: string
  visibility: EnumKnowledgeBaseVisibility
  translationMissing: boolean
  position: number
  title?: string | null
}

// The translation is named by what the breadcrumb renders of it rather than picked whole: the
//   answer header and the browse pre-info select different parts of it.
export type CategoryBreadcrumb = (Pick<
  KnowledgeBaseCategory,
  'id' | 'categoryIcon' | 'iconSet' | 'visibility'
> & { translation?: Maybe<Pick<KnowledgeBaseCategoryTranslation, 'title'>> })[]

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
