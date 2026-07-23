// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import { useRouter } from 'vue-router'

import type { KnowledgeBaseCategoryPreInfoFragment } from '#shared/graphql/types.ts'
import { redirectToError, ErrorRouteType } from '#shared/router/error.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { ErrorStatusCodes, GraphQLErrorTypes } from '#shared/types/error.ts'

import { KnowledgeBaseCategoryPreInfoFragmentDoc } from '#desktop/entities/knowledge-base/graphql/fragments/knowledgeBaseCategoryPreInfo.api.ts'
import { useKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.api.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'

import type { CategoryBreadcrumb } from '../types.ts'

export const useKnowledgeBaseCategorySubcategories = (
  options: {
    categoryId?: Ref<string | undefined>
    locale?: Ref<string | undefined>
  } = {},
) => {
  const { categoryId, locale } = options

  const router = useRouter()
  const store = useKnowledgeBaseStore()

  const knowledgeBaseCategorySubcategories = new QueryHandler(
    useKnowledgeBaseCategorySubcategoriesQuery(() => ({
      categoryId: categoryId?.value,
      locale: locale?.value,
    })),
    {
      // Opening a category the user may not browse (stale link, revoked access,
      //   a permission change) is answered with a 403 — route to the not-found
      //   page instead of a broken view, and skip the toast since the redirect
      //   is the feedback.
      errorCallback: (error) => {
        if (error.type === GraphQLErrorTypes.Forbidden) {
          // Forget this path first: it is the last visited one, so without
          //   clearing it the section's locale-less entry would send us straight
          //   back to the forbidden category — a redirect loop.
          store.rememberPath('')
          redirectToError(router, {
            type: ErrorRouteType.AuthenticatedError,
            statusCode: ErrorStatusCodes.NotFound,
            title: __('Not found'),
            message: __('This knowledge base category is not available.'),
            // Offer a way back into the section instead of a dead end. Target the
            //   locale-less entry so its guard resolves the user's preferred
            //   locale rather than the (forbidden) category's one.
            backLink: {
              label: __('Go to knowledge base'),
              link: knowledgeBaseBrowseRoute(),
            },
          })
          return false
        }
        return true
      },
    },
  )

  const result = knowledgeBaseCategorySubcategories.result()
  const loading = knowledgeBaseCategorySubcategories.loadingWithoutCachedResult()

  const content = computed(() => result.value?.knowledgeBaseCategorySubcategories)
  const subcategories = computed(() => content.value?.subcategories ?? [])

  // The opened category is already normalized in the cache — it was one of the
  //   subcategories on the page it was opened from, carrying its breadcrumb and
  //   next-level count. Reading it by id lets the header render instantly on
  //   navigation, before this category's own query resolves.
  const cachedCategory = computed<KnowledgeBaseCategoryPreInfoFragment | null>(() => {
    if (!categoryId?.value) return null

    return getApolloClient().cache.readFragment<KnowledgeBaseCategoryPreInfoFragment>({
      id: `KnowledgeBaseCategory:${categoryId.value}`,
      fragment: KnowledgeBaseCategoryPreInfoFragmentDoc,
    })
  })

  // Once loaded, use the authoritative breadcrumb from the response (reactive to
  //   content updates); while opening, use the cached one so the header appears
  //   instantly. Empty at the root or on a cold entry.
  const breadcrumb = computed<CategoryBreadcrumb>(() =>
    loading.value
      ? (cachedCategory.value?.breadcrumb ?? [])
      : (content.value?.category?.breadcrumb ?? []),
  )

  // Next-level count of the opened category (from the cache), to size the
  //   skeleton while it loads.
  const directSubcategoryCount = computed(() => cachedCategory.value?.directSubcategoryCount)

  // Whether the opened category shows public content in the current locale, so
  //   the header can decide whether to offer its "view public knowledge base"
  //   link (editors get it regardless).
  const visiblePublicly = computed(() => content.value?.category?.isVisiblePublicly)

  // Whether the opened category has no own translation in the browsed locale
  //   (its title falls back to another locale), so the browse view can warn.
  //   False at the root, where no single category is opened.
  const translationMissing = computed(() => Boolean(content.value?.category?.translationMissing))

  // Refetch on a content update only when it is relevant to what is shown: a
  //   knowledge-base-wide change (empty), or one touching the current category,
  //   a breadcrumb ancestor, or a displayed child (whose subtree counts and
  //   visibility may shift). Ancestors are in the category's breadcrumb, so a
  //   change deep in a child's subtree still lists that child.
  const { contentUpdates } = store

  contentUpdates.onResult(({ data }) => {
    // At the root there is no category id to match against, and a newly created
    //   or newly visible top-level category (e.g. after a permission change) is
    //   not yet in the displayed set — its ping carries only its own id. But any
    //   content change can shift the root listing (its top-level categories and
    //   their subtree counts), so always refetch there.
    if (!categoryId?.value) {
      knowledgeBaseCategorySubcategories.refetch()
      return
    }

    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []

    const displayedCategoryIds = new Set([
      categoryId.value,
      ...(content.value?.category?.breadcrumb ?? []).map((category) => category.id),
      ...subcategories.value.map((category) => category.id),
    ])

    if (affected.length === 0 || affected.some((id) => displayedCategoryIds.has(id))) {
      knowledgeBaseCategorySubcategories.refetch()
    }
  })

  return {
    knowledgeBaseCategorySubcategories,
    breadcrumb,
    subcategories,
    loading,
    directSubcategoryCount,
    visiblePublicly,
    translationMissing,
  }
}
