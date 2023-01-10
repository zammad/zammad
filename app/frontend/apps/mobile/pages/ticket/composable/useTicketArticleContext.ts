// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { PopupItem } from '@mobile/components/CommonSectionPopup'
import { useDialog } from '@shared/composables/useDialog'
import { computed, ref, shallowRef } from 'vue'
import { MutationHandler } from '@shared/server/apollo/handler'
import { useTicketArticleChangeVisibilityMutation } from '@shared/entities/article/graphql/mutations/change_visibility.api'
import type { TicketArticle } from '../types/tickets'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const ticketInternalId = ref(0)
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const isInternal = computed<boolean>(
    () => articleForContext.value?.internal || false,
  )

  const changeVisibilityAction = (
    articleId: string,
    targetInternalState: boolean,
  ) => {
    const errorNotificationMessage = targetInternalState
      ? __('The article could not be set to internal.')
      : __('The article could not be set to public.')

    const mutation = new MutationHandler(
      useTicketArticleChangeVisibilityMutation({
        variables: { articleId, internal: targetInternalState },
      }),
      { errorNotificationMessage },
    )

    mutation.send()
  }

  const contextOptions = computed<PopupItem[]>(() => {
    const articleId = articleForContext.value?.id
    if (!articleId) return []

    const targetInternalState = !isInternal.value

    return [
      {
        label: targetInternalState
          ? __('Set to internal')
          : __('Set to public'),
        onAction: () => changeVisibilityAction(articleId, targetInternalState),
      },
      {
        label: __('Reply'),
        onAction() {
          console.log('reply')
        },
      },
      {
        label: __('Forward'),
        onAction() {
          console.log('forward')
        },
      },
      {
        label: __('Split'),
        onAction() {
          console.log('split')
        },
      },
      {
        label: __('Show meta data'),
        noHideOnSelect: true,
        onAction() {
          metadataDialog.open({
            name: metadataDialog.name,
            article: articleForContext.value,
            ticketInternalId: ticketInternalId.value,
          })
        },
      },
    ]
  })

  const articleContextShown = computed({
    get: () => articleForContext.value != null,
    set: (value) => {
      // we don't care for "true", because to make it truthy we
      // call showArticleContext
      // setting it to "false" is done via "update:modelValue"
      if (!value) {
        articleForContext.value = undefined
      }
    },
  })

  const showArticleContext = (article: TicketArticle, ticketId: number) => {
    metadataDialog.prefetch()
    articleForContext.value = article
    ticketInternalId.value = ticketId
  }

  return {
    contextOptions,
    articleContextShown,
    showArticleContext,
  }
}
