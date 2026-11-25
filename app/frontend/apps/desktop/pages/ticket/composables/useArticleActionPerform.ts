// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import type { FormRefParameter } from '#shared/components/Form/types.ts'
import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import type {
  TicketArticleAction,
  TicketArticlePerformOptions,
} from '#shared/entities/ticket-article/action/plugins/types.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import { usePendingArticleAction } from '#shared/entities/ticket-article/composables/usePendingArticleAction/usePendingArticleAction.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'
import log from '#shared/utils/log.ts'

import type { Ref } from 'vue'

interface ArticleActionPerformContext {
  ticket: Ref<TicketById | undefined>
  form: FormRefParameter
  articleTranslation: Pick<TicketArticleTranslation, 'isTranslationDisplayed'>
  openReplyForm: TicketArticlePerformOptions['openReplyForm']
  getNewArticleBody: TicketArticlePerformOptions['getNewArticleBody']
}

const articleSelection = (articleInternalId: number) => {
  try {
    // Can throw RangeError.
    return getArticleSelection(articleInternalId)
  } catch (err) {
    log.error('[Article Quote] Failed to parse article selection', err)
    return undefined
  }
}

/**
 * Performs the actions of an article, as its action list and the reply shortcut do: on the text
 *   selected in it, and with the reply form remembering the article it answers.
 */
export const useArticleActionPerform = (context: ArticleActionPerformContext) => {
  const { isPending, isActionPending, performAction } = usePendingArticleAction()

  const { notify } = useNotifications()

  const performArticleAction = (action: TicketArticleAction, article: TicketArticle) => {
    if (!context.ticket.value) return

    const selection = articleSelection(article.internalId)

    // A translation takes the place of the original in the article body, so a quote of
    //   it would read as if the customer had written it.
    const isQuoteRefused =
      !!(selection?.html || selection?.text) &&
      context.articleTranslation.isTranslationDisplayed(article.id)

    if (isQuoteRefused && action.quotesSelection)
      notify({
        id: 'article-translation-quote-refused',
        type: NotificationTypes.Warn,
        message: __('Translated text cannot be quoted. Show the original to quote it.'),
      })

    return performAction(action, context.ticket.value, article, {
      formId: context.form.value?.formId ?? '',
      selection: isQuoteRefused ? undefined : selection,
      openReplyForm: (values) =>
        context.openReplyForm({ ...values, answeredArticleId: article.id }),
      getNewArticleBody: context.getNewArticleBody,
    })
  }

  return { isPending, isActionPending, performArticleAction }
}
