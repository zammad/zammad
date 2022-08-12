// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { PopupItem } from '@mobile/components/CommonSectionPopup'
import { useDialog } from '@shared/composables/useDialog'
import { computed, ref, shallowRef } from 'vue'
import type { TicketArticle } from '../types/tickets'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const ticketInternalId = ref(0)
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const contextOptions: PopupItem[] = [
    {
      label: __('Make internal'),
      onAction() {
        console.log('make internal')
      },
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
      onAction() {
        metadataDialog.open({
          name: metadataDialog.name,
          article: articleForContext.value,
          ticketInternalId: ticketInternalId.value,
        })
      },
    },
  ]

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
