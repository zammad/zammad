// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, reactive, watch, type Ref } from 'vue'

export const useUnreadArticle = <T>({ cleanupDependency }: { cleanupDependency: Ref<T> }) => {
  const unreadArticleIds = reactive<Set<string>>(new Set())

  const clearUnreadArticles = () => unreadArticleIds.clear()

  watch(cleanupDependency, () => {
    if (!unreadArticleIds.size) return
    clearUnreadArticles()
  })

  const addUnreadArticle = (articleId: string) => unreadArticleIds.add(articleId)

  const hasUnreadArticle = computed(() => unreadArticleIds.size > 0)

  const articleCount = computed(() => unreadArticleIds.size)

  return { articleCount, hasUnreadArticle, addUnreadArticle, unreadArticleIds, clearUnreadArticles }
}
