// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { PopupItem } from '@mobile/components/CommonSectionPopup'
import { useDialog } from '@shared/composables/useDialog'
import { computed, shallowRef } from 'vue'
import type { TicketArticle } from '../types/tickets'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const contextOptions: PopupItem[] = [
    {
      title: __('Make internal'),
      onAction() {
        console.log('make internal')
      },
    },
    {
      title: __('Reply'),
      onAction() {
        console.log('reply')
      },
    },
    {
      title: __('Forward'),
      onAction() {
        console.log('forward')
      },
    },
    {
      title: __('Split'),
      onAction() {
        console.log('split')
      },
    },
    {
      title: __('Show meta data'),
      onAction() {
        metadataDialog.open({
          name: metadataDialog.name,
          article: articleForContext.value,
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

  const showArticleContext = (article: TicketArticle) => {
    metadataDialog.prefetch()
    articleForContext.value = article
  }

  return {
    contextOptions,
    articleContextShown,
    showArticleContext,
  }
}
