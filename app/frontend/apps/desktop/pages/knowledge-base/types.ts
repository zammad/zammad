// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumKnowledgeBaseVisibility,
  KnowledgeBaseCategory,
} from '#shared/graphql/schema-types.ts'

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
  'id' | 'title' | 'categoryIcon' | 'visibility'
>[]
