// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ErrorRouteType, redirectErrorRoute } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import type { RouteLocationNormalized } from 'vue-router'

// Shared by every knowledge base route that carries its locale directly in the URL (the create and
//   the edit view) instead of going through the section shell, which resolves the locale itself
//   (KnowledgeBase.vue) and so never needs this guard.
//
// Without it, a locale the knowledge base does not have - a hand-edited URL, or a stale taskbar tab
//   whose locale was removed since - would open a form that cannot be written in the language the
//   URL names.
export const useKnowledgeBaseLocaleGuard = () => {
  const checkKnownLocale = async (to: RouteLocationNormalized) => {
    const store = useKnowledgeBaseStore()

    await store.ensureLoaded()

    const locale = to.params.localeCode as string

    if (store.isKnownLocale(locale)) return true

    return redirectErrorRoute({
      type: ErrorRouteType.AuthenticatedError,
      statusCode: ErrorStatusCodes.NotFound,
      title: __('Not found'),
      message: __('This knowledge base is not available in the selected language.'),
    })
  }

  return { checkKnownLocale }
}
