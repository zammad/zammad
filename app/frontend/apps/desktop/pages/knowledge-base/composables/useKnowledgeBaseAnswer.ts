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
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

export const useKnowledgeBaseAnswer = (
  options: {
    answerId?: Ref<string | undefined>
    locale?: Ref<string | undefined>
    // The reader route has no taskbar tab to fall back on, so a 403/404 has to redirect itself
    //   away from the broken view (the default). The edit route is a taskbar tab instead:
    //   LayoutTaskbarTabContent has already gated its content on the tab's own entity access
    //   before this ever runs, so there is nothing left for a race to redirect to here - just
    //   silence the toast, like the ticket detail view does for its own ticket query.
    redirectOnAccessError?: boolean
    // Also load the body the way an editor has to (`bodyForEditing`) rather than only the rendered
    //   one a reader gets. Off by default so a reader does not pay for rendering the body twice.
    withBodyForEditing?: boolean
    // The previous/next answer of the category, for the reader's stepper. Turn it off where there
    //   is no stepper (the edit view): it also switches off the two neighbour prefetches below.
    withNavigation?: boolean
  } = {},
) => {
  const {
    answerId,
    locale,
    redirectOnAccessError = true,
    withBodyForEditing = false,
    withNavigation = true,
  } = options

  const router = useRouter()
  const store = useKnowledgeBaseStore()

  const knowledgeBaseAnswerQuery = new QueryHandler(
    useKnowledgeBaseAnswerQuery(
      () => ({
        answerId: answerId?.value as string,
        locale: locale?.value,
        withBodyForEditing,
        withNavigation,
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
          if (!redirectOnAccessError) return false

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

  // Whether what `answer` holds is what the server last said, rather than a cache entry that no
  //   round trip has confirmed. The app queries `cache-and-network` (see the Apollo client's
  //   defaults), so a complete cache entry is served first and `loading` stays true until the
  //   network result lands - which is exactly the distinction `loading` above throws away, on
  //   purpose, to keep a cached render from flickering a skeleton.
  //
  // Anything that has to be measured against the *stored* state needs this one instead of that:
  //   a stale cached entry that a later network result contradicts would otherwise read as a
  //   change somebody else made (see useKnowledgeBaseAnswerConcurrentChange).
  //
  // A *successful* result, so the error is part of the condition rather than only the settlement:
  //   a refresh that fails leaves the cached result in place and sets `loading` to false, which
  //   would otherwise confirm precisely the unconfirmed answer this is here to catch.
  //
  // It stays false until a query succeeds again, which is the refetch below, a remount of the view,
  //   or a change of `answerId`/`locale` - not the answer subscription, whose push updates the data
  //   without clearing the query's error. This query does not refetch on reconnect either
  //   (QueryHandler only wires that up for a handler that asks for
  //   `triggerRefetchOnConnectionReconnect`).
  const answerConfirmed = computed(
    () =>
      !knowledgeBaseAnswerQuery.loading().value &&
      !knowledgeBaseAnswerQuery.operationError().value &&
      Boolean(result.value?.knowledgeBaseAnswer),
  )

  // Pushes every edit of the answer *itself* into the cache - title and body (their translation
  //   `belongs_to :answer, touch: true`), category, visibility, tags, attachments - because
  //   KnowledgeBase::Answer::TriggersSubscriptions fires on a plain `after_commit`, so a touch is
  //   enough. It carries the same field set the query asks for, so Apollo merges it into the one
  //   normalized `KnowledgeBaseAnswer:<id>` entity and no `updateQuery` is needed.
  //
  // What it cannot deliver is a change to a record this view renders while the answer is not it:
  //   the category chain behind the breadcrumb (`belongs_to :category, touch: true` touches the
  //   category when an answer is saved, never the answers when the category is, so renaming or
  //   moving one fires no answer subscription at all), and the knowledge base itself. Those only
  //   ping `contentUpdates` - which is what the refetch below is for, and the only thing it is
  //   needed for.
  knowledgeBaseAnswerQuery.subscribeToMore<
    KnowledgeBaseAnswerUpdatesSubscriptionVariables,
    KnowledgeBaseAnswerUpdatesSubscription
  >(() => ({
    document: KnowledgeBaseAnswerUpdatesDocument,
    variables: {
      answerId: answerId?.value as string,
      locale: locale?.value,
      // The same field set the query asked for: a subscription result that left `bodyForEditing`
      //   out would overwrite the cache entity without it, and the open editor would lose the
      //   only body it can load.
      withBodyForEditing,
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
  //   Without `navigation` there are no neighbours to warm, so this is a no-op for a caller that
  //   turned it off - the edit view runs neither prefetch.
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
        // Inherited, not hardcoded: the identity that makes this a cache hit includes the
        //   variables, so the prefetch has to ask for exactly what the view it warms will ask for.
        withBodyForEditing,
        withNavigation,
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
  //
  // It overlaps the subscription above rather than complementing it: saving the answer pings this
  //   too, with its own category among the affected ids, so an ordinary edit both pushes and
  //   refetches. Telling the two apart would need the ping to say which record changed, it being
  //   content-free by design.
  const { contentUpdates } = store

  const { off: stopContentUpdates } = contentUpdates.onResult(({ data }) => {
    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []
    const breadcrumbIds = answer.value?.category.breadcrumb.map((category) => category.id) ?? []

    if (affected.length === 0 || breadcrumbIds.some((id) => affected.includes(id))) {
      // Pin the refetch to the current reactive args explicitly: Vue only pushes
      //   a changed `answerId`/`locale` into the underlying query on its next
      //   reactivity flush, so a ping arriving in the same tick as a locale
      //   switch would otherwise refetch with the args being navigated away from.
      // Caught, because QueryHandler.refetch *rejects* on failure: nothing awaits this one, and a
      //   failed refresh is already handled by the handler itself (`operationError`, which
      //   `answerConfirmed` above reads). Without it a ping arriving offline raises an unhandled
      //   rejection - the same reason the handler's own reconnect refetch catches (QueryHandler).
      knowledgeBaseAnswerQuery
        .refetch({
          answerId: answerId?.value as string,
          locale: locale?.value,
        })
        .catch(() => {})
    }
  })

  onScopeDispose(stopContentUpdates)

  return { knowledgeBaseAnswerQuery, answer, answerConfirmed, loading }
}
