// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { controlledComputed } from '@vueuse/shared'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

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

interface SystemRaw {
  type: 'system'
  subject?: Maybe<string>
  to?: Maybe<string>
  reaction?: Maybe<string>
}

export type TicketArticleRow = (
  | ArticleRow
  | SystemRaw
  | MoreRow
  | ArticleDeliveryRow
) & {
  key: string
}

export const useTicketArticleRows = (
  articles: Ref<TicketArticle[]>,
  leadingNodesCount: Ref<number>,
  totalCount: Ref<number>,
) => {
  const rows = controlledComputed(articles, () => {
    const needMoreButton = articles.value.length < totalCount.value

    return articles.value.reduce((memo, article, index) => {
      if (article.preferences?.delivery_message) {
        memo.push({
          type: 'delivery',
          content: article.bodyWithUrls,
          key: article.internalId.toString(),
        })
      } else if (
        article.sender?.name === 'System' &&
        article.type?.name !== 'note'
      ) {
        memo.push({
          type: 'system',
          subject: article.subject,
          to: article.to?.raw || '',
          reaction: article.preferences?.whatsapp?.reaction?.emoji,
          key: article.internalId.toString(),
        })
      } else {
        memo.push({
          type: 'article-bubble',
          article,
          key: article.internalId.toString(),
        })
      }

      if (index === leadingNodesCount.value - 1 && needMoreButton) {
        memo.push({
          type: 'more',
          key: 'more',

          count: totalCount.value - articles.value.length,
        })
      }
      return memo
    }, [] as TicketArticleRow[])
  })
  return { rows }
}
