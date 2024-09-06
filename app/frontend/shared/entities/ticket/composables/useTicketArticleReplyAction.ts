// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import type {
  EditorContentType,
  FieldEditorContext,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormRefParameter } from '#shared/components/Form/types.ts'
import type { TicketArticlePerformOptions } from '#shared/entities/ticket-article/action/plugins/types.ts'

import type { FormKitNode } from '@formkit/core'

export const useTicketArticleReplyAction = (
  form: FormRefParameter,
  showArticleReply: () => void | Promise<void>,
) => {
  const openReplyForm: TicketArticlePerformOptions['openReplyForm'] = async (
    values = {},
  ) => {
    const formNode = form.value?.formNode as FormKitNode

    await showArticleReply()

    const { articleType, ...otherOptions } = values

    const typeNode = formNode.find('articleType', 'name')
    if (formNode.context) {
      Object.assign(formNode.context, { _open: true })
    }

    typeNode?.input(articleType, false)

    // Trigger new fields that depend on the articleType.
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

  return {
    openReplyForm,
    getNewArticleBody,
  }
}
