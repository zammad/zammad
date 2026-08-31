// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import getUuid from '#shared/utils/getUuid.ts'

import { useKnowledgeBaseLocaleGuard } from './useKnowledgeBaseLocaleGuard.ts'

import type { RouteLocationNormalized } from 'vue-router'

export const useKnowledgeBaseAnswerCreateView = () => {
  const { checkKnownLocale } = useKnowledgeBaseLocaleGuard()

  // A create view is a taskbar tab, and a tab needs an identity before anything can be stored for
  //   it - so a URL without one is redirected to a fresh draft, like ticket create does. Two tabs
  //   for the same draft cannot happen this way: the id comes from the URL, never from the state.
  const checkKnowledgeBaseAnswerCreateRoute = async (to: RouteLocationNormalized) => {
    const localeCheck = await checkKnownLocale(to)
    if (localeCheck !== true) return localeCheck

    if (!to.params.tabId) {
      return {
        name: 'KnowledgeBaseAnswerCreate',
        params: { ...to.params, tabId: getUuid() },
        query: to.query,
      }
    }

    return true
  }

  return { checkKnowledgeBaseAnswerCreateRoute }
}
