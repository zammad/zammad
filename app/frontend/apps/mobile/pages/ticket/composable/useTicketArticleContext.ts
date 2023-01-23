// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { PopupItem } from '@mobile/components/CommonSectionPopup'
import { useDialog } from '@shared/composables/useDialog'
import { computed, ref, shallowRef } from 'vue'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import { createArticleActions } from '@shared/entities/ticket-article/action/plugins'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const ticketForContext = shallowRef<TicketById>()
  const selectionRange = ref<Range>()
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const triggerId = ref(0)

  const recalculate = () => {
    triggerId.value += 1
  }

  const disposeCallbacks: (() => unknown)[] = []
  const onDispose = (callback: () => unknown) => {
    disposeCallbacks.push(callback)
  }

  const contextOptions = computed<PopupItem[]>(() => {
    const ticket = ticketForContext.value
    const article = articleForContext.value

    // trigger ID cannot be less than 0, so it's just a hint for vue to recalculate computed
    if (!article || !ticket || triggerId.value < 0) return []

    // clear all side effects before recalculating
    disposeCallbacks.forEach((callback) => callback())
    disposeCallbacks.length = 0

    const actions = createArticleActions(ticket, article, 'mobile', {
      recalculate,
      onDispose,
    }).map((action) => {
      const { perform, link, label } = action
      if (!perform) return action
      return {
        label,
        link,
        onAction: () =>
          perform(ticket, article, { selection: selectionRange.value }),
      }
    })

    return [
      ...actions,
      {
        label: __('Show meta data'),
        onAction() {
          metadataDialog.open({
            name: metadataDialog.name,
            article,
            ticketInternalId: ticket.internalId,
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
        // TODO: add tests, when we have an action that uses it
        disposeCallbacks.forEach((callback) => callback())
        disposeCallbacks.length = 0
      }
    },
  })

  const showArticleContext = (article: TicketArticle, ticket: TicketById) => {
    metadataDialog.prefetch()
    articleForContext.value = article
    ticketForContext.value = ticket
    try {
      // TODO: only put range, if it's inside the article
      // can throw RangeError
      selectionRange.value = window.getSelection()?.getRangeAt(0)
    } catch {
      selectionRange.value = undefined
    }
  }

  return {
    contextOptions,
    articleContextShown,
    showArticleContext,
  }
}
