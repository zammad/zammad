// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import type {
  EditorContentType,
  FieldEditorContext,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormRefParameter, FormSchemaField } from '#shared/components/Form/types.ts'
import type { TicketArticlePerformOptions } from '#shared/entities/ticket-article/action/plugins/types.ts'

import type { FormKitNode } from '@formkit/core'

export const useTicketArticleReplyAction = (
  form: FormRefParameter,
  showArticleReply: () => void | Promise<void>,
) => {
  const openReplyForm: TicketArticlePerformOptions['openReplyForm'] = async (values = {}) => {
    const formNode = form.value?.formNode as FormKitNode

    await showArticleReply()

    const { articleType, ...otherOptions } = values

    if (formNode.context) {
      Object.assign(formNode.context, { _open: true })
    }

    const changedArticleFields: Record<string, Partial<FormSchemaField>> = {
      articleType: {
        value: articleType,
      },
    }

    for (const [key, value] of Object.entries(otherOptions)) {
      changedArticleFields[key] = {
        value,
      }
      // TODO: make handling more generic(?)
      if (key === 'to' || key === 'cc') {
        const options = Array.isArray(value)
          ? value.map((v) => ({ value: v, label: v }))
          : [{ value, label: value }]

        changedArticleFields[key].props ||= {}
        changedArticleFields[key].props.options = options
      }
    }

    form.value?.updateChangedFields(changedArticleFields)

    formNode.emit('article-reply-open', articleType)

    //.Required for firefox to stabilize the quoted text
    if (changedArticleFields.body?.value !== undefined) {
      const bodyValue = changedArticleFields.body.value

      formNode?.settled?.then(() => {
        const bodyNode = form.value?.getNodeByName('body')
        if (!bodyNode || bodyNode.value === bodyValue) return
        bodyNode.input(bodyValue, false)
      })
    }

    const context = formNode.find('body', 'name')?.context as FieldEditorContext | undefined

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
