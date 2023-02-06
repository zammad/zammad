// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { MutationHandler } from '@shared/server/apollo/handler'
import type { ApolloCache } from '@apollo/client/cache'
import type { InMemoryCache } from '@apollo/client/core'
import { useTicketArticleDeleteMutation } from '@shared/entities/ticket-article/graphql/mutations/delete.api'
import { useApplicationStore } from '@shared/stores/application'
import { useSessionStore } from '@shared/stores/session'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import { TicketArticlesDocument } from '@mobile/pages/ticket/graphql/queries/ticket/articles.api'
import type { TicketArticleEdge } from '@shared/graphql/types'
import type { TicketArticleActionPlugin, TicketArticleAction } from './types'

const updateCacheAfterRemoving = (
  cache: ApolloCache<InMemoryCache>,
  ticket: TicketById,
  article: TicketArticle,
) => {
  const application = useApplicationStore()

  cache.updateQuery(
    {
      query: TicketArticlesDocument,
      variables: {
        ticketId: ticket.id,
        pageSize: Number(application.config.ticket_articles_min ?? 5),
      },
    },
    (data) => {
      const edges = data.articles.edges.filter(
        (elem: TicketArticleEdge) => elem.node.id !== article.id,
      )

      return {
        ...data,
        articles: {
          ...data.articles,
          edges,
          totalCount: data.articles.totalCount - 1,
        },
      }
    },
  )

  cache.gc()
}

const deleteAction = async (ticket: TicketById, article: TicketArticle) => {
  const { waitForConfirmation } = useConfirmation()

  const confirmed = await waitForConfirmation(
    __('Are you sure to remove this article?'),
  )

  if (!confirmed) return

  const mutation = new MutationHandler(
    useTicketArticleDeleteMutation({
      variables: { articleId: article.id },
      update(cache) {
        updateCacheAfterRemoving(cache, ticket, article)
      },
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

  if (article.createdBy?.id !== session.userId) return false

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
      icon: { mobile: 'trash' },
      perform: () => deleteAction(ticket, article),
      view: {
        agent: ['change'],
      },
    }

    return [action]
  },
}

export default actionPlugin
