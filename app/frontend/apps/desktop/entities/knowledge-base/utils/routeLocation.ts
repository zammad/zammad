// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import type { RouteLocationNamedRaw } from 'vue-router'

// The knowledge base root listing and a single category are two separate routes
//   — a category carries `/category/:id` in the URL (mirroring the `/answer/:id`
//   route below). This picks the right target from what a caller has, so
//   callers don't juggle the two route names and params themselves. Omitting the
//   locale targets the section entry, whose guard resolves the user's preferred
//   locale (falling back to the primary, or not-found when there is none).
export const knowledgeBaseBrowseRoute = (
  localeCode?: string,
  categoryId?: string,
): RouteLocationNamedRaw => {
  if (localeCode && categoryId) {
    return {
      name: 'KnowledgeBaseCategory',
      // Use the internal id in the URL; the GraphQL global id would be
      //   percent-encoded into an unreadable path segment.
      params: { localeCode, categoryInternalId: getIdFromGraphQLId(categoryId) },
    }
  }

  return { name: 'KnowledgeBaseBrowse', params: localeCode ? { localeCode } : {} }
}

// An answer is addressed by its locale alone - it does not sit below the
//   category it was browsed from (internal id in the URL, as above).
export const knowledgeBaseAnswerRoute = (
  localeCode: string,
  answerId: string,
): RouteLocationNamedRaw => ({
  name: 'KnowledgeBaseAnswer',
  params: { localeCode, answerInternalId: getIdFromGraphQLId(answerId) },
})

// An answer's own `url` — what the picker offers and what the server resolves an answer link's
//   href to — is an app-absolute path, since it is written into a document as an href. A router
//   location is relative to the app's mount point instead, so that comes off again to follow the
//   link without a full page load.
export const knowledgeBaseAnswerRouteFromUrl = (url: string) => url.replace(/^\/desktop/, '')

// A create draft is one answer translation, so the locale is part of its URL and switching the
//   language opens *another* draft instead of retitling this one. Every call mints a fresh tab
//   id accordingly; an existing draft is reopened through its taskbar tab link.
//
// `categoryId` is the internal id the category field of the form works with (the form updater
//   reads it back to preselect the category), not the GraphQL one.
export const knowledgeBaseAnswerCreateRoute = (
  localeCode: string,
  categoryId?: string | number,
): RouteLocationNamedRaw => ({
  name: 'KnowledgeBaseAnswerCreate',
  params: { localeCode, tabId: getUuid() },
  query: categoryId ? { categoryId } : {},
})
