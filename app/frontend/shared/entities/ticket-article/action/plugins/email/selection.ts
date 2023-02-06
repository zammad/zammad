// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '@shared/entities/ticket/types'
import { i18n } from '@shared/i18n'
import type { ConfigList } from '@shared/types/store'
import { htmlCleanup, textToHtml, textCleanup } from '@shared/utils/helpers'
import type { SelectionData } from '@shared/utils/selection'

const formatDate = (date: string) => {
  const options = {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  } as const
  try {
    return new Date(date).toLocaleTimeString(i18n.locale(), options)
  } catch {
    return new Date(date).toLocaleTimeString('en-US', options)
  }
}

export const getReplyQuoteHeader = (
  config: ConfigList,
  article: TicketArticle,
) => {
  if (!config.ui_ticket_zoom_article_email_full_quote_header) return ''

  const date = formatDate(article.createdAt)
  const name = article.originBy?.fullname || article.createdBy.fullname || ''

  return `${i18n.t('On %s, %s wrote:', date, name)}<br><br>`
}

export const getArticleSelection = (
  selection: SelectionData | undefined,
  article: TicketArticle,
  config: ConfigList,
) => {
  if (selection?.html) {
    const clean = htmlCleanup(selection.html)
    if (clean) return { content: clean, full: false }
  }
  if (selection?.text) {
    return { content: textToHtml(selection.text), full: false }
  }
  if (config.ui_ticket_zoom_article_email_full_quote) {
    const cleanBody = textCleanup(article.bodyWithUrls)
    const content =
      article.contentType === 'text/html' ? cleanBody : textToHtml(cleanBody)

    return { content, full: true }
  }
  return { content: null, full: false }
}
