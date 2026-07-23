// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { useLastVisitedPath } from '#desktop/composables/useLastVisitedPath.ts'

import { useKnowledgeBaseQuery } from '../graphql/queries/knowledgeBase.api'
import { useKnowledgeBaseContentUpdatesSubscription } from '../graphql/subscriptions/knowledgeBaseContentUpdates.api'

export const useKnowledgeBaseStore = defineStore('knowledgeBase', () => {
  const router = useRouter()

  // The URL is the single source of truth for the browsed locale — every browse
  //   route carries it, so there is no separate reactive state to keep in sync.
  const activeLocale = computed(
    () => router.currentRoute.value.params.localeCode as string | undefined,
  )

  const knowledgeBaseQuery = new QueryHandler(
    useKnowledgeBaseQuery(
      () => ({
        locale: activeLocale.value,
      }),
      {
        context: {
          batch: {
            active: false,
          },
        },
      },
    ),
  )

  const result = knowledgeBaseQuery.result()
  const knowledgeBase = computed(() => result.value?.knowledgeBase)
  const loading = knowledgeBaseQuery.loadingWithoutCachedResult()

  const kbLocales = computed(() => knowledgeBase.value?.kbLocales ?? [])

  const isKnownLocale = (locale: string) =>
    kbLocales.value.some((kbLocale) => kbLocale.systemLocale.locale === locale)

  // Let the entry guard await the base query before deciding the URL; instant
  //   when it is already (pre)loaded — the app warms it right after login.
  const ensureLoaded = () => knowledgeBaseQuery.loaded()

  // The last browsed knowledge base URL, so the locale-less entry (the sidebar
  //   link) returns you to where you were rather than the root.
  const { previousPath, rememberPath } = useLastVisitedPath()

  // The subscription is a content-free ping: a single change invalidates the
  //   per-user, tree-wide answer counts, so we just refetch the knowledge base query.
  //   It is only needed while the section is actually being browsed — gating it
  //   on the URL locale means the app-level preload warms the query without
  //   holding an open subscription for users who never enter the knowledge base.
  const contentUpdates = new SubscriptionHandler(
    useKnowledgeBaseContentUpdatesSubscription(() => ({
      enabled: Boolean(activeLocale.value),
    })),
  )

  contentUpdates.onResult(({ data }) => {
    // Only a knowledge-base-wide change (empty affected list — the KB record or
    //   its translations) affects this base data (title/locales); content edits
    //   carry affected category ids and are handled by the browse queries.
    if (data?.knowledgeBaseContentUpdates?.affectedCategoryIds?.length) return

    knowledgeBaseQuery.refetch()
  })

  return {
    knowledgeBase,
    loading,
    activeLocale,
    kbLocales,
    isKnownLocale,
    ensureLoaded,
    previousPath,
    rememberPath,
    contentUpdates,
  }
})
