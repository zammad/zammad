// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import type { TicketById } from '@shared/entities/ticket/types'
import type {
  FormHandler,
  FormHandlerFunction,
  FormValues,
} from '@shared/components/Form'
import { FormHandlerExecution } from '@shared/components/Form'
import type { FieldEditorContext } from '@shared/components/Form/fields/FieldEditor/types'
import type { ChangedField } from '@shared/components/Form/types'
import { useTicketSignatureLazyQuery } from '@shared/graphql/queries/ticketSignature.api'
import { convertToGraphQLId, getIdFromGraphQLId } from '@shared/graphql/utils'
import { QueryHandler } from '@shared/server/apollo/handler'
import type { Ref } from 'vue'
import type {
  TicketSignatureQuery,
  TicketSignatureQueryVariables,
} from '@shared/graphql/types'

let signatureQuery: QueryHandler<
  TicketSignatureQuery,
  TicketSignatureQueryVariables
>

export const getTicketSignatureQuery = () => {
  if (signatureQuery) return signatureQuery

  signatureQuery = new QueryHandler(
    useTicketSignatureLazyQuery({ groupId: '' }),
  )

  return signatureQuery
}

// TODO: can maybe be moved inside ticket entity?
export const useTicketSignature = (ticket?: Ref<TicketById | undefined>) => {
  const signatureQuery = getTicketSignatureQuery()

  const getValue = (
    values: FormValues,
    changedField: ChangedField,
    name: string,
  ) => {
    return changedField.name === name ? changedField.newValue : values[name]
  }

  const signatureHandling = (editorName: string): FormHandler => {
    const handleSignature: FormHandlerFunction = (
      execution,
      formNode,
      values,
      changeFields,
      updateSchemaDataField,
      schemaData,
      changedField,
    ) => {
      if (
        changedField?.name !== 'group_id' &&
        changedField?.name !== 'articleSenderType'
      )
        return

      const editorContext = getNode(editorName)?.context as
        | FieldEditorContext
        | undefined
      if (!editorContext) return

      const groupId = getValue(values, changedField, 'group_id')

      if (!groupId) return

      const senderType = getValue(values, changedField, 'articleSenderType')

      if (senderType !== 'email-out') {
        editorContext.removeSignature?.()
        return
      }

      signatureQuery
        .trigger({
          groupId: convertToGraphQLId('Group', String(groupId)),
          ticketId: ticket?.value?.id,
        })
        .then((signature) => {
          const body = signature?.ticketSignature?.renderedBody
          const id = signature?.ticketSignature?.id
          if (!body || !id) {
            editorContext.removeSignature()
            return
          }
          editorContext.addSignature({ body, id: getIdFromGraphQLId(id) })
        })
    }

    return {
      execution: [
        FormHandlerExecution.Initial,
        FormHandlerExecution.FieldChange,
      ],
      callback: handleSignature,
    }
  }

  return {
    signatureHandling,
  }
}
