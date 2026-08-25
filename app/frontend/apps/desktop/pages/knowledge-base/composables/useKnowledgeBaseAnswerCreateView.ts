// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ErrorRouteType, redirectErrorRoute } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import type { RouteLocationNormalized } from 'vue-router'

export const useKnowledgeBaseAnswerCreateView = () => {
  // A create view is a taskbar tab, and a tab needs an identity before anything can be stored for
  //   it - so a URL without one is redirected to a fresh draft, like ticket create does. Two tabs
  //   for the same draft cannot happen this way: the id comes from the URL, never from the state.
  //
  // The locale is checked against the knowledge base as well, which the section shell does for
  //   every browse URL (KnowledgeBase.vue) and this route does not inherit. Without it a stale tab
  //   - a locale removed from the knowledge base since - or a hand-edited URL would open a draft
  //   in a language that cannot be written, with a blank locale selector to show for it.
  const checkKnowledgeBaseAnswerCreateRoute = async (to: RouteLocationNormalized) => {
    const store = useKnowledgeBaseStore()

    await store.ensureLoaded()

    const locale = to.params.localeCode as string

    if (!store.isKnownLocale(locale)) {
      return redirectErrorRoute({
        type: ErrorRouteType.AuthenticatedError,
        statusCode: ErrorStatusCodes.NotFound,
        title: __('Not found'),
        message: __('This knowledge base is not available in the selected language.'),
      })
    }

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
