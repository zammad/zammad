// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleTranslationTargetLocalesQuery } from '#shared/graphql/types.ts'

import type { ComputedRef } from 'vue'

export type ArticleTranslationTargetLocale =
  TicketArticleTranslationTargetLocalesQuery['ticketArticleTranslationTargetLocales'][number]

export interface ArticleTranslationResult {
  content?: Maybe<string>
  backend?: Maybe<string>
  // False when the article is already in the target language, so nothing was translated.
  translated?: Maybe<boolean>
}

export type ArticleTranslation =
  | { status: 'pending' }
  | ({ status: 'done' } & ArticleTranslationResult)
  | { status: 'error'; error: string }

// What one ticket tab knows about the translations of its articles, see useTicketArticleTranslation.
export interface TicketArticleTranslation {
  translationFor: (articleId: string) => ArticleTranslation | undefined
  isTranslationActive: (articleId: string) => boolean
  hasDirectTranslationAction: (articleId: string) => boolean
  showTranslation: (articleId: string) => Promise<void>
  showOriginal: (articleId: string) => void
  isTranslating: ComputedRef<boolean>
}
