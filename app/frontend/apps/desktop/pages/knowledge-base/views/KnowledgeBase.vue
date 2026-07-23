<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts">
import { ErrorRouteType, redirectErrorRoute } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'

import type { NavigationGuard } from 'vue-router'

const notFound = () =>
  redirectErrorRoute({
    type: ErrorRouteType.AuthenticatedError,
    statusCode: ErrorStatusCodes.NotFound,
    title: __('Not found'),
    message: __('This knowledge base is not available in the selected language.'),
  })

// Entering the section: reconcile the URL against the base query. A locale-less
//   entry (the sidebar link / empty alias) returns you to the last browsed page
//   — or, on a first visit, the locale the backend resolved — and an
//   unconfigured URL locale is a section-level not-found.
const resolveEntry: NavigationGuard = async (to) => {
  const store = useKnowledgeBaseStore()

  const locale = to.params.localeCode as string | undefined

  // Locale-less entry with a remembered page: return straight to it — no query.
  if (!locale && store.previousPath) return store.previousPath

  await store.ensureLoaded()

  // The base query failed to load (network/GraphQL) — its handler already
  //   surfaced a notification, so route to a generic error rather than masking
  //   the failure as a language-specific not-found.
  if (!store.knowledgeBase) {
    return redirectErrorRoute({
      type: ErrorRouteType.AuthenticatedError,
      statusCode: ErrorStatusCodes.InternalError,
      title: __('Error'),
      message: __('The knowledge base could not be loaded.'),
    })
  }

  if (!locale) {
    const resolvedLocale = store.knowledgeBase?.currentLocale?.systemLocale.locale

    return resolvedLocale ? knowledgeBaseBrowseRoute(resolvedLocale) : notFound()
  }

  if (!store.isKnownLocale(locale)) return notFound()

  // Remember the current page so the locale-less entry can return here.
  store.rememberPath(to.fullPath)

  return true
}

// Navigating within the section: the base query is already loaded, but a
//   param-only change on the reused route (e.g. a hand-edited URL locale) isn't
//   guaranteed to come from the (valid-only) selector, so it still needs the
//   same not-found guard as entry before being remembered.
const rememberEntry: NavigationGuard = (to) => {
  const store = useKnowledgeBaseStore()

  const locale = to.params.localeCode as string | undefined

  if (!locale) return store.previousPath

  if (!store.isKnownLocale(locale)) return notFound()

  store.rememberPath(to.fullPath)

  return true
}
</script>

<script setup lang="ts">
// `beforeRouteEnter` reconciles the URL when entering the section (needs the
//   query); `beforeRouteUpdate` only handles param-only changes within it (e.g.
//   re-clicking the sidebar back to the locale-less URL), where the query is
//   already resolved — same split of concerns as the personal settings section.
defineOptions({
  beforeRouteEnter: resolveEntry,
  beforeRouteUpdate: rememberEntry,
})
</script>

<!-- The browse view is the only child; keep it alive so its state (scroll,
     loaded data) survives leaving and returning. -->
<template>
  <RouterView #default="{ Component }">
    <KeepAlive :max="1">
      <component :is="Component" />
    </KeepAlive>
  </RouterView>
</template>
