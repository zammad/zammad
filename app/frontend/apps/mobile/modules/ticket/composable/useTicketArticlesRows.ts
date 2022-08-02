// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { Ref } from 'vue'
import { computed } from 'vue'
import type { TicketArticle } from '../types/tickets'

interface ArticleRow {
  type: 'article-bubble'
  article: TicketArticle
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
) & {
  key: string
}

export const useTicketArticleRows = (articles: Ref<TicketArticle[]>) => {
  const rows = computed(() => {
    const rows: TicketArticleRow[] = []
    const dates = new Set<string>()
    // assuming it is sorted by createdAt
    articles.value.forEach((article) => {
      const date = i18n.date(article.createdAt)
      if (!dates.has(date)) {
        dates.add(date)
        rows.push({
          type: 'date',
          date: article.createdAt,
          key: date,
        })
      }
      if (article.sender?.name === 'System' && article.type?.name !== 'note') {
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
    })
    return rows
  })

  return { rows }
}
