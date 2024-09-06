// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, shallowRef } from 'vue'

import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import log from '#shared/utils/log.ts'
import type { SelectionData } from '#shared/utils/selection.ts'

import type { PopupItemDescriptor } from '#mobile/components/CommonSectionPopup/types.ts'
import { useDialog } from '#mobile/composables/useDialog.ts'

import { useTicketInformation } from './useTicketInformation.ts'

export const useTicketArticleContext = () => {
  const articleForContext = shallowRef<TicketArticle>()
  const ticketForContext = shallowRef<TicketById>()
  const selectionData = ref<SelectionData>()
  const metadataDialog = useDialog({
    name: 'article-metadata',
    component: () =>
      import('../components/TicketDetailView/ArticleMetadataDialog.vue'),
  })

  const { showArticleReplyDialog, form } = useTicketInformation()

  const { openReplyForm, getNewArticleBody } = useTicketArticleReplyAction(
    form,
    showArticleReplyDialog,
  )

  const triggerId = ref(0)

  const recalculate = () => {
    triggerId.value += 1
  }

  const disposeCallbacks: (() => unknown)[] = []
  const onDispose = (callback: () => unknown) => {
    disposeCallbacks.push(callback)
  }

  const contextOptions = computed<PopupItemDescriptor[]>(() => {
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
    }).map<PopupItemDescriptor>((action) => {
      const { perform, link, label } = action
      if (!perform) return { ...action, type: 'link' }
      return {
        type: link ? 'link' : 'button',
        label,
        link,
        onAction: () =>
          perform(ticket, article, {
            formId: form.value?.formId || '',
            selection: selectionData.value,
            openReplyForm,
            getNewArticleBody,
          }),
      }
    })

    return [
      ...actions,
      {
        type: 'button',
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
      // can throw RangeError
      selectionData.value = getArticleSelection(article.internalId)
    } catch (err) {
      log.error('[Article Quote] Failed to parse article selection', err)
      selectionData.value = undefined
    }
  }

  return {
    contextOptions,
    articleContextShown,
    showArticleContext,
  }
}
