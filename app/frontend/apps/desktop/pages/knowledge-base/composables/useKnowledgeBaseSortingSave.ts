// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import UserError from '#shared/errors/UserError.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useKnowledgeBaseReorderAnswersMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderAnswers.api.ts'
import { useKnowledgeBaseReorderCategoriesMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderCategories.api.ts'
import { useKnowledgeBaseReorderRootCategoriesMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderRootCategories.api.ts'

import {
  useKnowledgeBaseSorting,
  type KnowledgeBaseSortingChange,
} from './useKnowledgeBaseSorting.ts'

/**
 * Persists what the sorting bar staged: one reorder mutation per list that moved, and the
 * rearrange state left behind once they all went through.
 *
 * @param categoryId — the browsed node, or undefined at the knowledge base root, which sorts its
 *   top level categories through a mutation of its own and holds no answers at all.
 */
export const useKnowledgeBaseSortingSave = (categoryId: Ref<string | undefined>) => {
  const { pendingChanges, resetKnowledgeBaseSorting } = useKnowledgeBaseSorting()
  const { notify } = useNotifications()

  const isSaving = ref(false)

  // The listing the saved order is read back from. Named rather than refetched by hand, so the
  //   page comes back in the stored order without this composable having to own either query.
  const REFETCH_ON_CATEGORY_ORDER = ['knowledgeBaseCategorySubcategories']
  const REFETCH_ON_ANSWER_ORDER = ['knowledgeBaseAnswers']

  const sendCategoryChange = ({ sortingMode, orderedIds }: KnowledgeBaseSortingChange) => {
    // A category arranges the children below it; the root has no such argument to name, so the
    //   top level is its own mutation (Gql::Mutations::KnowledgeBase::Reorder::RootCategories).
    if (!categoryId.value) {
      return new MutationHandler(
        useKnowledgeBaseReorderRootCategoriesMutation(() => ({
          refetchQueries: REFETCH_ON_CATEGORY_ORDER,
        })),
      ).send({ sortingMode, categoryIds: orderedIds })
    }

    return new MutationHandler(
      useKnowledgeBaseReorderCategoriesMutation(() => ({
        refetchQueries: REFETCH_ON_CATEGORY_ORDER,
      })),
    ).send({ parentCategoryId: categoryId.value, sortingMode, categoryIds: orderedIds })
  }

  const sendAnswerChange = ({ sortingMode, orderedIds }: KnowledgeBaseSortingChange) =>
    new MutationHandler(
      useKnowledgeBaseReorderAnswersMutation(() => ({
        refetchQueries: REFETCH_ON_ANSWER_ORDER,
      })),
    ).send({ categoryId: categoryId.value as string, sortingMode, answerIds: orderedIds })

  const sendChange = (change: KnowledgeBaseSortingChange) =>
    change.scope === 'answers' ? sendAnswerChange(change) : sendCategoryChange(change)

  const saveSorting = async () => {
    if (isSaving.value) return

    // Both lists of one category write to the same record — one column each — so they go one
    //   after the other rather than racing each other for it.
    const changes = pendingChanges.value.filter(
      // There are no answers at the root, so no category to name in the mutation. Unreachable
      //   through the UI, which offers the scope tabs only inside a category, but a mode staged
      //   for a scope that is not there must never be sent.
      (change) => change.scope !== 'answers' || Boolean(categoryId.value),
    )

    if (!changes.length) {
      resetKnowledgeBaseSorting()
      return
    }

    isSaving.value = true

    try {
      for (const change of changes) {
        // Sequential on purpose, see above.
        // oxlint-disable-next-line no-await-in-loop
        await sendChange(change)
      }
    } catch (error) {
      // A refusal from the backend — a list that changed underneath the editor is the likely one,
      //   since an order has to name every record of its scope. Keep the state armed so the work
      //   is not lost; the listing has by then refetched into whatever is actually there.
      notify({
        id: 'knowledge-base-sorting-error',
        type: NotificationTypes.Error,
        message:
          error instanceof UserError
            ? error.getFirstErrorMessage()
            : __('The changes could not be saved.'),
      })
      return
    } finally {
      isSaving.value = false
    }

    resetKnowledgeBaseSorting()
  }

  return { isSaving, saveSorting }
}
