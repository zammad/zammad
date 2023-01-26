// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { PopupItem } from '@mobile/components/CommonSectionPopup'
import { useDialog } from '@shared/composables/useDialog'
import { computed, nextTick, ref, shallowRef } from 'vue'
import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import { createArticleActions } from '@shared/entities/ticket-article/action/plugins'
import type { TicketArticlePerformOptions } from '@shared/entities/ticket-article/action/plugins/types'
import { useTicketInformation } from './useTicketInformation'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const ticketForContext = shallowRef<TicketById>()
  const selectionRange = ref<Range>()
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const { showArticleReplyDialog, form } = useTicketInformation()

  const triggerId = ref(0)

  const recalculate = () => {
    triggerId.value += 1
  }

  const disposeCallbacks: (() => unknown)[] = []
  const onDispose = (callback: () => unknown) => {
    disposeCallbacks.push(callback)
  }

  const openReplyDialog: TicketArticlePerformOptions['openReplyDialog'] =
    async (values = {}) => {
      const formNode = form.value?.formNode
      if (!formNode) return

      await showArticleReplyDialog()

      const { articleType, ...otherOptions } = values

      formNode.find('articleType')?.input(articleType, false)
      // trigger new fields that depend on the articleType
      await nextTick()

      for (const [key, value] of Object.entries(otherOptions)) {
        const node = formNode.find(key, 'name')
        node?.input(value, false)
        // TODO: make handling more generic(?)
        if (node && (key === 'to' || key === 'cc')) {
          const options = Array.isArray(value)
            ? value.map((v) => ({ value: v, label: v }))
            : [{ value, label: value }]
          node.emit('prop:options', options)
        }
      }
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
          perform(ticket, article, {
            selection: selectionRange.value,
            openReplyDialog,
          }),
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
