// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { controlledComputed } from '@vueuse/shared'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { isUnprocessableEmailArticle } from '#shared/entities/ticket-article/composables/useTicketArticleUnprocessableEmail.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTicketInformation } from './useTicketInformation.ts'

import type { Ref } from 'vue'

export const ARTICLE_PAGE_SIZE = 100

interface ArticleRow {
  type: 'article-bubble'
  article: TicketArticle
}

interface UnprocessableEmailRow {
  type: 'unprocessable-email'
  article: TicketArticle
}

interface ArticleDeliveryRow {
  type: 'delivery'
  content: string
}

interface MoreRow {
  type: 'more'
  count: number
}

interface NewRow {
  type: 'new'
}

interface DateRow {
  type: 'date'
  date: string
}

interface SystemRaw {
  type: 'system'
  subject?: Maybe<string>
  to?: Maybe<string>
  reaction?: Maybe<string>
}

type TicketArticleRow = (
  | ArticleRow
  | UnprocessableEmailRow
  | SystemRaw
  | MoreRow
  | NewRow
  | DateRow
  | ArticleDeliveryRow
) & {
  key: string
}

const articleRow = (article: TicketArticle): TicketArticleRow => {
  const key = article.id

  if (isUnprocessableEmailArticle(article)) {
    return { type: 'unprocessable-email', article, key }
  }
  if (article.preferences?.delivery_message) {
    return { type: 'delivery', content: article.bodyWithUrls, key }
  }
  if (
    article.sender?.name === EnumTicketArticleSenderName.System &&
    article.type?.name !== 'note'
  ) {
    return {
      type: 'system',
      subject: article.subject,
      to: article.to?.raw || '',
      reaction: article.preferences?.whatsapp?.reaction?.emoji,
      key,
    }
  }
  return { type: 'article-bubble', article, key }
}

export const useTicketArticleRows = (articles: Ref<TicketArticle[]>, totalCount: Ref<number>) => {
  const { newArticlesIds } = useTicketInformation()
  const session = useSessionStore()

  const rows = controlledComputed(articles, () => {
    const rows: TicketArticleRow[] = []
    const dates = new Set<string>()
    const needMoreButton = articles.value.length < totalCount.value
    let hasNew = false
    // assuming it is sorted by createdAt
    articles.value.forEach((article, index) => {
      const date = i18n.date(article.createdAt)
      // The warning of an unprocessable email stands on its own, without a date separator.
      if (!isUnprocessableEmailArticle(article) && !dates.has(date)) {
        dates.add(date)
        rows.push({
          type: 'date',
          date: article.createdAt,
          key: date,
        })
      }
      rows.push(articleRow(article))
      // after "description" (always first) article is added, add "more" button
      if (index === 0 && needMoreButton) {
        const remainingCount = totalCount.value - articles.value.length

        rows.push({
          type: 'more',
          key: 'more',
          count: remainingCount > ARTICLE_PAGE_SIZE ? ARTICLE_PAGE_SIZE : remainingCount,
        })
      }
      const next = articles.value[index + 1]
      if (!hasNew && next && session.userId !== next.author.id && newArticlesIds.has(next.id)) {
        hasNew = true
        rows.push({
          type: 'new',
          key: 'new',
        })
      }
    })
    return rows
  })

  return { rows }
}
