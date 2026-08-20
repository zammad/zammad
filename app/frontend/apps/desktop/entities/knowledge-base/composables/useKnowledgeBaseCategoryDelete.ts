// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import UserError from '#shared/errors/UserError.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useKnowledgeBaseCategoryDeleteMutation } from '../graphql/mutations/knowledgeBaseCategoryDelete.api.ts'
import { useKnowledgeBaseStore } from '../stores/knowledgeBase.ts'
import { knowledgeBaseBrowseRoute } from '../utils/routeLocation.ts'

import type { DeletableKnowledgeBaseCategory } from '../types.ts'

// What the delete flow needs to know about its category, satisfied by both entry points
//   (the browse card and the header acting on the opened category).
//
// `isDeletable` is undefined while the header's category query is still in flight — its
//   menu is reachable before that resolves, since the cached breadcrumb renders the
//   header at once. Unknown then means "let the server decide", never "refuse".

export const useKnowledgeBaseCategoryDelete = () => {
  const router = useRouter()
  const store = useKnowledgeBaseStore()

  const { waitForConfirmation } = useConfirmation()

  // Also the messenger for the backend refusal: the client check is a UX nicety only, the
  //   authoritative answer arrives as a user error (a category can gain content between
  //   rendering the card and confirming).
  const showCannotDeleteDialog = (message?: string) =>
    waitForConfirmation(message || __('Delete all child categories and answers, then try again.'), {
      headerTitle: __('Cannot delete category'),
      buttonLabel: __('OK'),
      hideCancelButton: true,
    })

  // Deleting from a tile in the listing stays put — only pulling the page the user is
  //   standing on away warrants a navigation.
  const isOpenedCategory = (categoryId: string) =>
    router.currentRoute.value.name === 'KnowledgeBaseCategory' &&
    router.currentRoute.value.params.categoryInternalId === String(getIdFromGraphQLId(categoryId))

  const deleteCategory = async (
    category: DeletableKnowledgeBaseCategory,
    parentCategoryId?: Maybe<string>,
  ) => {
    const opened = isOpenedCategory(category.id)

    const deleteMutation = new MutationHandler(
      useKnowledgeBaseCategoryDeleteMutation(() => ({
        variables: { categoryId: category.id },
        update(cache, { data }) {
          // A refused delete is an ordinary payload with user errors, so Apollo runs this
          //   either way — evicting then would drop a category that is still there.
          if (!data?.knowledgeBaseCategoryDelete?.success) return

          // Drop the category from the cache right away, so its tile disappears without
          //   waiting out the refetch round trip.
          cache.evict({
            id: cache.identify({ __typename: 'KnowledgeBaseCategory', id: category.id }),
          })
          cache.gc()
        },
        // Refresh the listing the tile was deleted from. Not when navigating away: the
        //   active browse query still carries the deleted category's id, which the backend
        //   can no longer answer — the navigation itself triggers the parent's fetch.
        refetchQueries: opened ? [] : ['knowledgeBaseCategorySubcategories'],
      })),
    )

    try {
      await deleteMutation.send()
    } catch (error) {
      if (error instanceof UserError) showCannotDeleteDialog(error.getFirstErrorMessage())
      return
    }

    // Replace, not push: the deleted category's URL is a dead end now, so it has no
    //   business staying reachable via the back button. The section's route guard then
    //   re-remembers the new path, so the last-visited entry stops pointing at the
    //   deleted category too.
    if (opened) {
      router.replace(knowledgeBaseBrowseRoute(store.activeLocale, parentCategoryId ?? undefined))
    }
  }

  // The whole flow: guard, confirm, mutate, navigate.
  //
  // @param options.parentCategoryId — post-delete navigation target when the deleted
  //   category is the one currently open; omitted or nil means the localised root.
  const confirmCategoryDelete = async (
    category: DeletableKnowledgeBaseCategory,
    options: { parentCategoryId?: Maybe<string> } = {},
  ) => {
    // Only a known-negative answer refuses up front; see the interface above.
    if (category.isDeletable === false) {
      await showCannotDeleteDialog()
      return
    }

    const confirmed = await waitForConfirmation(__('Do you really want to delete "%s"?'), {
      confirmationVariant: 'delete',
      textPlaceholder: [category.title ?? ''],
    })

    if (!confirmed) return

    await deleteCategory(category, options.parentCategoryId)
  }

  return { confirmCategoryDelete }
}
