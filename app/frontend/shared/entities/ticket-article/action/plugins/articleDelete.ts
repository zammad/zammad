// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleDeleteMutation } from '#shared/entities/ticket-article/graphql/mutations/delete.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { TicketArticleActionPlugin, TicketArticleAction } from './types.ts'

const deleteAction = async (article: TicketArticle) => {
  const { waitForConfirmation } = useConfirmation()

  const confirmed = await waitForConfirmation(
    __('Are you sure to remove this article?'),
  )

  if (!confirmed) return

  const mutation = new MutationHandler(
    useTicketArticleDeleteMutation({
      variables: { articleId: article.id },
    }),
    { errorNotificationMessage: __('The article could not be deleted.') },
  )

  mutation.send()
}

const hasDeleteTimeframe = (deleteTimeframe: number) =>
  deleteTimeframe && deleteTimeframe > 0

const secondsToDelete = (article: TicketArticle, deleteTimeframe: number) => {
  if (!hasDeleteTimeframe(deleteTimeframe)) return 0

  const now = new Date().getTime()
  const createdAt = new Date(article.createdAt).getTime()
  const secondsSinceCreated = (now - createdAt) / 1000

  if (secondsSinceCreated > deleteTimeframe) return 0

  return deleteTimeframe - secondsSinceCreated
}

const isDeletable = (article: TicketArticle, deleteTimeframe: number) => {
  const session = useSessionStore()

  if (article.author?.id !== session.userId) return false

  if (article.type?.communication && !article.internal) return false

  if (
    hasDeleteTimeframe(deleteTimeframe) &&
    !secondsToDelete(article, deleteTimeframe)
  )
    return false

  return true
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 999,

  addActions(ticket, article, { onDispose, recalculate, config }) {
    const deleteTimeframe =
      config.ui_ticket_zoom_article_delete_timeframe as number

    if (!isDeletable(article, deleteTimeframe)) return []

    const seconds = secondsToDelete(article, deleteTimeframe)

    if (seconds) {
      const timeout = window.setTimeout(() => {
        recalculate()
      }, seconds * 1_000)

      onDispose(() => {
        window.clearTimeout(timeout)
      })
    }

    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Delete Article'),
      name: 'articleDelete',
      icon: 'trash',
      perform: () => deleteAction(article),
      view: {
        agent: ['change'],
      },
    }

    return [action]
  },
}

export default actionPlugin
