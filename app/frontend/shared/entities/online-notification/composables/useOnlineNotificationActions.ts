// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import { useOnlineNotificationDeleteMutation } from '#shared/entities/online-notification/graphql/mutations/delete.api.ts'
import { useOnlineNotificationMarkAllAsSeenMutation } from '#shared/entities/online-notification/graphql/mutations/markAllAsSeen.api.ts'
import { useOnlineNotificationSeenMutation } from '#shared/entities/online-notification/graphql/mutations/seen.api.ts'
import { OnlineNotificationsDocument } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.api.ts'
import type {
  OnlineNotification,
  OnlineNotificationsQuery,
  Scalars,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

export const useOnlineNotificationActions = () => {
  const { cache } = getApolloClient()

  const getCacheData = () => {
    const queryOptions = {
      query: OnlineNotificationsDocument,
    }
    const existingQueryCache =
      cache.readQuery<OnlineNotificationsQuery>(queryOptions)

    if (!existingQueryCache?.onlineNotifications) return null

    const oldQueryCache = cloneDeep(existingQueryCache)

    return { queryOptions, oldQueryCache, existingQueryCache }
  }

  const removeNotificationCacheUpdate = (id: Scalars['ID']['output']) => {
    const data = getCacheData()

    if (!data) return

    const { queryOptions, oldQueryCache, existingQueryCache } = data

    cache.writeQuery({
      ...queryOptions,
      data: {
        onlineNotifications: {
          edges: existingQueryCache.onlineNotifications.edges.filter(
            (edge) => edge.node.id !== id,
          ),
          pageInfo: existingQueryCache.onlineNotifications.pageInfo,
        },
      },
    })

    return () => {
      cache.writeQuery({
        ...queryOptions,
        data: oldQueryCache,
      })
    }
  }

  const updateAllSeenNotificationCache = (ids: Scalars['ID']['output'][]) => {
    const data = getCacheData()

    if (!data) return

    const { queryOptions, oldQueryCache, existingQueryCache } = data

    const clonedQueryCache = cloneDeep(existingQueryCache)

    ids.forEach((id) =>
      clonedQueryCache.onlineNotifications.edges.forEach(({ node }) => {
        if (node.id === id) {
          node.seen = true
        }
      }),
    )

    cache.writeQuery({
      ...queryOptions,
      data: {
        onlineNotifications: {
          ...clonedQueryCache.onlineNotifications,
        },
      },
    })

    return () => {
      cache.writeQuery({
        ...queryOptions,
        data: oldQueryCache,
      })
    }
  }

  const updateSeenNotificationCache = (id: Scalars['ID']['output']) => {
    const data = getCacheData()

    if (!data) return

    const { queryOptions, oldQueryCache, existingQueryCache } = data

    const clonedQueryCache = cloneDeep(existingQueryCache)

    clonedQueryCache.onlineNotifications.edges.forEach(({ node }) => {
      if ((node.metaObject as OnlineNotification['metaObject'])?.id === id) {
        node.seen = true
      }
    })

    cache.writeQuery({
      ...queryOptions,
      data: {
        onlineNotifications: {
          ...clonedQueryCache.onlineNotifications,
        },
      },
    })

    return () => {
      cache.writeQuery({
        ...queryOptions,
        data: oldQueryCache,
      })
    }
  }

  const seenNotificationMutation = new MutationHandler(
    useOnlineNotificationSeenMutation(),
    {
      errorNotificationMessage: __(
        'The online notification could not be marked as seen.',
      ),
    },
  )

  const seenNotification = async (id: Scalars['ID']['output']) => {
    const revertCache = updateSeenNotificationCache(id)

    return seenNotificationMutation
      .send({ objectId: id })
      .catch(() => revertCache)
  }

  const markAllSeenMutation = new MutationHandler(
    useOnlineNotificationMarkAllAsSeenMutation(),
    {
      errorNotificationMessage: __('Cannot set online notifications as seen'),
    },
  )

  const markAllRead = (ids: Scalars['ID']['output'][]) => {
    const revertCache = updateAllSeenNotificationCache(ids)

    return markAllSeenMutation
      .send({ onlineNotificationIds: ids })
      .catch(() => revertCache)
  }

  const deleteNotificationMutation = new MutationHandler(
    useOnlineNotificationDeleteMutation(),
  )

  const deleteNotification = async (id: Scalars['ID']['output']) => {
    const revertCache = removeNotificationCacheUpdate(id)

    return deleteNotificationMutation
      .send({
        onlineNotificationId: id,
      })
      .catch(() => revertCache)
  }

  return {
    seenNotification,
    deleteNotification,
    deleteNotificationMutation,
    markAllRead,
  }
}
