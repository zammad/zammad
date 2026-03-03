// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch, type WatchHandle } from 'vue'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type {
  FormHandler,
  FormHandlerFunction,
  FormValues,
  ChangedField,
} from '#shared/components/Form/types.ts'
import { FormHandlerExecution } from '#shared/components/Form/types.ts'

/**
 *
 * @param senderTypeName 'email' | 'email-out'
 * Ticket detail view expects 'email' as articleType for incoming emails
 * Ticket create form expects 'email-out' as articleType for outgoing emails
 */
export const useTicketSignature = (senderTypeName: 'email' | 'email-out' = 'email-out') => {
  const getValue = (values: FormValues, changedField: ChangedField | undefined, name: string) => {
    return changedField?.name === name ? changedField.newValue : values[name]
  }

  let signatureWatcher: WatchHandle | null = null

  const cleanUpSignatureHandler = () => {
    if (!signatureWatcher) return
    signatureWatcher.stop()

    signatureWatcher = null
  }

  const signatureHandling = (editorName: string): FormHandler => {
    const handleSignature: FormHandlerFunction = (execution, reactivity, data) => {
      const { formNode, values, changedField } = data

      if (
        execution === FormHandlerExecution.FieldChange &&
        changedField?.name !== 'group_id' &&
        changedField?.name !== 'articleSenderType'
      )
        return

      const editorContext = formNode?.find(editorName, 'name')?.context as
        | FieldEditorContext
        | undefined
      if (!editorContext) return

      const groupId = getValue(values, changedField, 'group_id')

      // email-out -> articleSenderType -> form field for ticket create
      // article.articleType -> used when new ticket article is added in ticket detail view
      const senderType =
        getValue(values, changedField, 'articleSenderType') ||
        (values?.article as Record<'articleType', string>)?.articleType

      cleanUpSignatureHandler()

      if (!groupId || senderType !== senderTypeName) {
        editorContext.removeSignature()
        return
      }

      signatureWatcher = watch(
        () => editorContext.signature,
        (signature) => {
          if (!signature) return editorContext.removeSignature()

          editorContext.addSignature({
            renderedBody: signature.renderedBody,
            internalId: signature.internalId,
          })
        },
        { flush: 'post' },
      )
    }

    return {
      execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
      callback: handleSignature,
    }
  }

  return {
    signatureHandling,
  }
}
