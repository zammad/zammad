// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type {
  FormHandler,
  FormHandlerFunction,
  FormValues,
  ChangedField,
} from '#shared/components/Form/types.ts'
import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useTicketSignatureLazyQuery } from '#shared/graphql/queries/ticketSignature.api.ts'
import type {
  TicketSignatureQuery,
  TicketSignatureQueryVariables,
} from '#shared/graphql/types.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import type { Ref } from 'vue'

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
      reactivity,
      data,
    ) => {
      const { formNode, values, changedField } = data

      if (
        changedField?.name !== 'group_id' &&
        changedField?.name !== 'articleSenderType'
      )
        return

      const editorContext = formNode?.find(editorName, 'name')?.context as
        | FieldEditorContext
        | undefined
      if (!editorContext) return

      const groupId = getValue(values, changedField, 'group_id')

      if (!groupId) {
        editorContext.removeSignature()
        return
      }

      const senderType = getValue(values, changedField, 'articleSenderType')

      if (senderType !== 'email-out') {
        editorContext.removeSignature?.()
        return
      }

      signatureQuery
        .query({
          variables: {
            groupId: convertToGraphQLId('Group', String(groupId)),
            ticketId: ticket?.value?.id,
          },
        })
        .then(({ data: signature }) => {
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
