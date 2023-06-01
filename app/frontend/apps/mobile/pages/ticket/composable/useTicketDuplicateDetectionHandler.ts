// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormHandlerExecution } from '#shared/components/Form/index.ts'
import type {
  ChangedField,
  FormHandler,
  FormHandlerFunction,
  ReactiveFormSchemData,
} from '#shared/components/Form/types.ts'

export type TicketDuplicateDetectionItem = [
  id: number,
  number: string,
  title: string,
]

export interface TicketDuplicateDetectionPayload {
  count: number
  items: TicketDuplicateDetectionItem[]
}

export const useTicketDuplicateDetectionHandler = (
  showTicketDuplicateDetectionDialog: (
    data: TicketDuplicateDetectionPayload,
  ) => void,
): FormHandler => {
  const executeHandler = (
    execution: FormHandlerExecution,
    schemaData: ReactiveFormSchemData,
    changedField?: ChangedField,
  ) => {
    if (!schemaData.fields.ticket_duplicate_detection) return false
    if (
      execution === FormHandlerExecution.FieldChange &&
      (!changedField || changedField.name !== 'ticket_duplicate_detection')
    ) {
      return false
    }

    return true
  }

  const handleTicketDuplicateDetection: FormHandlerFunction = async (
    execution,
    formNode,
    values,
    changeFields,
    updateSchemaDataField,
    schemaData,
    changedField,
  ) => {
    if (!executeHandler(execution, schemaData, changedField)) return

    const data =
      changedField?.newValue as unknown as TicketDuplicateDetectionPayload

    if (!data?.count) return

    showTicketDuplicateDetectionDialog(data)
  }

  return {
    execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
    callback: handleTicketDuplicateDetection,
  }
}
