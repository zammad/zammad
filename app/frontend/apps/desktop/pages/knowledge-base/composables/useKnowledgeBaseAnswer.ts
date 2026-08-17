// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onScopeDispose, type Ref } from 'vue'
import { useRouter } from 'vue-router'

import type {
  KnowledgeBaseAnswerUpdatesSubscription,
  KnowledgeBaseAnswerUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { redirectToError, ErrorRouteType } from '#shared/router/error.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { ErrorStatusCodes, GraphQLErrorTypes } from '#shared/types/error.ts'

import { useKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.api.ts'
import { KnowledgeBaseAnswerUpdatesDocument } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerUpdates.api.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'

export const useKnowledgeBaseAnswer = (
  options: {
    answerId?: Ref<string | undefined>
    locale?: Ref<string | undefined>
  } = {},
) => {
  const { answerId, locale } = options

  const router = useRouter()
  const store = useKnowledgeBaseStore()

  const knowledgeBaseAnswerQuery = new QueryHandler(
    useKnowledgeBaseAnswerQuery(
      () => ({
        answerId: answerId?.value as string,
        locale: locale?.value,
      }),
      () => ({ enabled: Boolean(answerId?.value) }),
    ),
    {
      // Opening an answer the user may not read (stale link, revoked access, an
      //   unpublished answer, a permission change) is answered with a 403 — route
      //   to the not-found page instead of a broken view, and skip the toast since
      //   the redirect is the feedback.
      errorCallback: (error) => {
        if (
          error.type === GraphQLErrorTypes.Forbidden ||
          error.type === GraphQLErrorTypes.RecordNotFound
        ) {
          // Forget this path first: it is the last visited one, so without
          //   clearing it the section's locale-less entry would send us straight
          //   back to the forbidden answer — a redirect loop.
          store.rememberPath('')
          redirectToError(router, {
            type: ErrorRouteType.AuthenticatedError,
            statusCode: ErrorStatusCodes.NotFound,
            title: __('Not found'),
            message: __('This knowledge base answer is not available.'),
            // Offer a way back into the section instead of a dead end. Target the
            //   locale-less entry so its guard resolves the user's preferred
            //   locale rather than the (forbidden) answer's one.
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

  const result = knowledgeBaseAnswerQuery.result()
  const loading = knowledgeBaseAnswerQuery.loadingWithoutCachedResult()

  // Pushes direct edits to the open answer's own fields (title, body, tags,
  //   attachments, edited-by, …) straight into the cache. Apollo merges them into
  //   the same normalized `KnowledgeBaseAnswer:<id>` entity the query above reads,
  //   so no explicit `updateQuery` is needed. Category/visibility changes still go
  //   through the coarse `contentUpdates` ping + refetch below, since those don't
  //   touch this answer's own row.
  knowledgeBaseAnswerQuery.subscribeToMore<
    KnowledgeBaseAnswerUpdatesSubscriptionVariables,
    KnowledgeBaseAnswerUpdatesSubscription
  >(() => ({
    document: KnowledgeBaseAnswerUpdatesDocument,
    variables: {
      answerId: answerId?.value as string,
      locale: locale?.value,
    },
  }))

  const answer = computed(() => result.value?.knowledgeBaseAnswer ?? undefined)

  const navigation = computed(() => answer.value?.navigation)

  // A single-answer category wraps both neighbours back to the answer itself —
  //   nothing to warm there.
  const neighbourAnswerId = (side: 'previousAnswer' | 'nextAnswer') =>
    computed(() =>
      navigation.value && navigation.value.totalCount > 1 ? navigation.value[side].id : undefined,
    )

  // Warm the cache with the neighbours the stepper links to, by running the very
  //   same query the router will execute on click. That identity is the point:
  //   Apollo only serves a result from the cache when the whole query's diff is
  //   complete, so anything short of the identical operation would still leave the
  //   view rendering skeletons for one round trip.
  //
  //   Deliberately not wrapped in QueryHandler: a background prefetch has to stay
  //   silent, whereas the handler above turns a forbidden answer into a redirect —
  //   which would navigate away from the answer the user is currently reading just
  //   because a neighbour is out of reach.
  const prefetchNeighbourAnswer = (answerId: Ref<string | undefined>) => {
    useKnowledgeBaseAnswerQuery(
      () => ({
        answerId: answerId.value as string,
        locale: locale?.value,
      }),
      () => ({
        enabled: Boolean(answerId.value),
        // Only a neighbour that is genuinely new costs a request; stepping back
        //   through already visited answers stays entirely in the cache.
        fetchPolicy: 'cache-first',
      }),
    )
  }

  prefetchNeighbourAnswer(neighbourAnswerId('previousAnswer'))
  prefetchNeighbourAnswer(neighbourAnswerId('nextAnswer'))

  // The content update ping is content-free, so refetch when it can concern this
  //   answer: a knowledge-base-wide change (empty list), or one touching the
  //   answer's own category or any of its ancestors — renaming/moving a
  //   category further up the tree still changes the breadcrumb rendered here,
  //   so matching only the direct category would leave it stale.
  const { contentUpdates } = store

  const { off: stopContentUpdates } = contentUpdates.onResult(({ data }) => {
    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []
    const breadcrumbIds = answer.value?.category.breadcrumb.map((category) => category.id) ?? []

    if (affected.length === 0 || breadcrumbIds.some((id) => affected.includes(id))) {
      // Pin the refetch to the current reactive args explicitly: Vue only pushes
      //   a changed `answerId`/`locale` into the underlying query on its next
      //   reactivity flush, so a ping arriving in the same tick as a locale
      //   switch would otherwise refetch with the args being navigated away from.
      knowledgeBaseAnswerQuery.refetch({
        answerId: answerId?.value as string,
        locale: locale?.value,
      })
    }
  })

  onScopeDispose(stopContentUpdates)

  return { knowledgeBaseAnswerQuery, answer, loading }
}
