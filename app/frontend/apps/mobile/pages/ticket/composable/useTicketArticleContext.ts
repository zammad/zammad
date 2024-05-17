// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, ref, shallowRef } from 'vue'

import type {
  EditorContentType,
  FieldEditorContext,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type {
  TicketArticle,
  TicketById,
} from '#shared/entities/ticket/types.ts'
import { createArticleActions } from '#shared/entities/ticket-article/action/plugins/index.ts'
import type { TicketArticlePerformOptions } from '#shared/entities/ticket-article/action/plugins/types.ts'
import { getArticleSelection } from '#shared/entities/ticket-article/composables/getArticleSelection.ts'
import log from '#shared/utils/log.ts'
import type { SelectionData } from '#shared/utils/selection.ts'

import type { PopupItemDescriptor } from '#mobile/components/CommonSectionPopup/types.ts'
import { useDialog } from '#mobile/composables/useDialog.ts'

import { useTicketInformation } from './useTicketInformation.ts'

import type { FormKitNode } from '@formkit/core'

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
      const formNode = form.value?.formNode as FormKitNode

      await showArticleReplyDialog()

      const { articleType, ...otherOptions } = values

      const typeNode = formNode.find('articleType', 'name')
      if (formNode.context) {
        Object.assign(formNode.context, { _open: true })
      }

      typeNode?.input(articleType, false)
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

      formNode.emit('article-reply-open', articleType)

      const context = formNode.find('body', 'name')?.context as
        | FieldEditorContext
        | undefined

      context?.focus()

      nextTick(() => {
        if (formNode.context) {
          Object.assign(formNode.context, { _open: false })
        }
      })
    }

  const getNewArticleBody = (type: EditorContentType): string => {
    const bodyElement = form.value?.getNodeByName('body')
    if (!bodyElement) return ''
    const getEditorValue = bodyElement.context?.getEditorValue
    return typeof getEditorValue === 'function' ? getEditorValue(type) : ''
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
            openReplyDialog,
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
