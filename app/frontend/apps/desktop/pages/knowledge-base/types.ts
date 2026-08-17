// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumKnowledgeBaseVisibility,
  KnowledgeBaseCategory,
  Scalars,
} from '#shared/graphql/schema-types.ts'
import type { KnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'

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

// Derived from the schema scalar, so the icon sprite file names cannot drift
//   from what the backend allows.
export type KnowledgeBaseIconSet = Scalars['KnowledgeBaseIconSet']['output']

export type KnowledgeBaseBreadcrumbItem = BreadcrumbItem & {
  iconSet?: KnowledgeBaseIconSet
  visibility?: EnumKnowledgeBaseVisibility
}
