// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { PopupItem } from '@mobile/components/CommonSectionPopup'
import { computed, shallowRef } from 'vue'
import { TicketArticle } from '../types/tickets'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()

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
        console.log('show meta data')
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
    articleForContext.value = article
  }

  return {
    contextOptions,
    articleContextShown,
    showArticleContext,
  }
}
