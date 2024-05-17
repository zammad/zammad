// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { controlledComputed } from '@vueuse/shared'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTicketInformation } from './useTicketInformation.ts'

import type { Ref } from 'vue'

interface ArticleRow {
  type: 'article-bubble'
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
}

type TicketArticleRow = (
  | ArticleRow
  | SystemRaw
  | MoreRow
  | NewRow
  | DateRow
  | ArticleDeliveryRow
) & {
  key: string
}

export const useTicketArticleRows = (
  articles: Ref<TicketArticle[]>,
  totalCount: Ref<number>,
) => {
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
      if (!dates.has(date)) {
        dates.add(date)
        rows.push({
          type: 'date',
          date: article.createdAt,
          key: date,
        })
      }
      if (article.preferences?.delivery_message) {
        rows.push({
          type: 'delivery',
          content: article.bodyWithUrls,
          key: article.id,
        })
      } else if (
        article.sender?.name === 'System' &&
        article.type?.name !== 'note'
      ) {
        rows.push({
          type: 'system',
          subject: article.subject,
          to: article.to?.raw || '',
          key: article.id,
        })
      } else {
        rows.push({
          type: 'article-bubble',
          article,
          key: article.id,
        })
      }
      // after "description" (always first) article is added, add "more" button
      if (index === 0 && needMoreButton) {
        rows.push({
          type: 'more',
          key: 'more',
          count: totalCount.value - articles.value.length,
        })
      }
      const next = articles.value[index + 1]
      if (
        !hasNew &&
        next &&
        session.userId !== next.author.id &&
        newArticlesIds.has(next.id)
      ) {
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
