// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useKnowledgeBaseAnswerDeleteMutation } from '../graphql/mutations/knowledgeBaseAnswerDelete.api.ts'
import { useKnowledgeBaseStore } from '../stores/knowledgeBase.ts'
import { knowledgeBaseBrowseRoute } from '../utils/routeLocation.ts'

import type { Reference, StoreObject } from '@apollo/client/core'

// The `knowledgeBaseAnswers` connection as it sits in the cache: edges holding references to the
//   normalized answers, not the denormalized query result. A cached field can always be a
//   reference to a normalized entity instead — a connection never is, but the modifier below has
//   to account for it all the same.
type CachedAnswerConnection =
  | Reference
  | {
      __typename?: string
      edges?: readonly { node?: Reference | StoreObject }[]
      totalCount?: number
    }

export const useKnowledgeBaseAnswerDelete = () => {
  const router = useRouter()
  const store = useKnowledgeBaseStore()

  const { waitForConfirmation } = useConfirmation()
  const { notify } = useNotifications()

  // @param options.categoryId — the category the answer is listed under: where to go when the
  //   deleted answer is the one being read (omitted or nil means the localised root), and which
  //   cached listing counted it.
  const confirmAnswerDelete = async (
    answer: { id: string; title?: Maybe<string> },
    options: { categoryId?: Maybe<string> } = {},
  ) => {
    const confirmed = await waitForConfirmation(__('Do you really want to delete "%s"?'), {
      confirmationVariant: 'delete',
      textPlaceholder: [answer.title ?? ''],
    })

    if (!confirmed) return

    const deleteMutation = new MutationHandler(
      useKnowledgeBaseAnswerDeleteMutation(() => ({
        variables: { answerId: answer.id },
        update(cache, { data }) {
          if (!data?.knowledgeBaseAnswerDelete?.success) return

          // The listing is edited in place rather than refetched: it is scrolled through page by
          //   page, and a refetch collapses it back to its first page — which, several pages in,
          //   throws the reader back to the top of the category.
          cache.modify({
            fields: {
              // Runs once per cached listing (the field is keyed by category and locale), so the
              //   open one and every other one still in the cache are reached alike. Dropping the
              //   edge needs no category; `storeFieldName` is consulted only for the count, when
              //   the answer sat on a page this listing never loaded and there is no edge to go by.
              knowledgeBaseAnswers(
                connection: CachedAnswerConnection,
                { readField, isReference, storeFieldName },
              ) {
                if (isReference(connection) || !connection.edges) return connection

                const edges = connection.edges.filter(
                  (edge) => readField('id', edge.node) !== answer.id,
                )

                const listedTheAnswer =
                  edges.length !== connection.edges.length ||
                  (!!options.categoryId &&
                    storeFieldName.includes(`"categoryId":${JSON.stringify(options.categoryId)}`))

                if (!listedTheAnswer) return connection

                return {
                  ...connection,
                  edges,
                  // Counts the whole listing, not the loaded window, so it is one lower now no
                  //   matter which page the answer sat on.
                  totalCount: Math.max((connection.totalCount ?? 0) - 1, 0),
                }
              },
            },
          })

          // Only now: the modifier above identifies the edge by reading the node's id, which an
          //   evicted entity no longer answers. Everything else pointing at the answer (the feed,
          //   search results) goes with it.
          cache.evict({ id: cache.identify({ __typename: 'KnowledgeBaseAnswer', id: answer.id }) })
          cache.gc()
        },
      })),
    )

    // Whichever view is currently open *on this exact answer* - the reader, or its own edit tab.
    const viewingAnswer =
      (router.currentRoute.value.name === 'KnowledgeBaseAnswer' ||
        router.currentRoute.value.name === 'KnowledgeBaseAnswerEdit') &&
      router.currentRoute.value.params.answerInternalId === String(getIdFromGraphQLId(answer.id))

    // Leaving *before* the delete, not after: the destroy pings the content-updates subscription,
    //   on which the reader refetches its answer, gets a not-found and lands on the error page.
    //   Replace, not push — the answer's URL is a dead end from here on. Not undone on failure: the
    //   answer is still there to navigate back to, and the failure's own notification (raised by
    //   the handler) explains why nothing else changed.
    if (viewingAnswer) {
      await router.replace(
        knowledgeBaseBrowseRoute(store.activeLocale, options.categoryId ?? undefined),
      )
    }

    try {
      await deleteMutation.send()
    } catch {
      return
    }

    notify({
      id: 'knowledge-base-answer-delete',
      type: NotificationTypes.Success,
      message: __('Knowledge base answer deleted successfully.'),
    })

    // The open edit tabs are not closed from here. `HasTaskbars#destroy_taskbars` already removed
    //   them inside the delete, and their removal reaches every affected client - this one and
    //   whoever else had the answer open - as the taskbar list subscription's `removeItem`.
    //   Deleting them again from here would ask the backend for a row it has just destroyed, whose
    //   not-found would surface as an error notification right behind the success one.
  }

  return { confirmAnswerDelete }
}
