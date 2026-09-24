// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  AiAnalyticsMetadata,
  TicketArticleTranslationTargetLocalesQuery,
} from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { ComputedRef } from 'vue'

export type ArticleTranslationTargetLocale =
  TicketArticleTranslationTargetLocalesQuery['ticketArticleTranslationTargetLocales'][number]

export interface ArticleTranslationResult {
  content?: Maybe<string>
  backend?: Maybe<string>
  // False when the article is already in the target language, so nothing was translated.
  translated?: Maybe<boolean>
  // The analytics run the translation came from, which a rating attaches to - recorded by every
  // translation service. Absent for a translation stored before that, which offers no feedback control.
  analytics?: Maybe<DeepPartial<AiAnalyticsMetadata>>
  // Another translation is on its way; this one stays shown until it arrives.
  regenerating?: boolean
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
  markTranslationRated: (articleId: string) => void
  regenerateTranslation: (articleId: string) => Promise<void>
}
