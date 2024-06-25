// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  ChangedField,
  FormHandler,
  FormHandlerFunction,
  ReactiveFormSchemData,
} from '#shared/components/Form/types.ts'
import type { TicketDuplicateDetectionItem } from '#shared/entities/ticket/types.ts'

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
    reactivity,
    data,
  ) => {
    const { changedField } = data
    const { schemaData } = reactivity

    if (!executeHandler(execution, schemaData, changedField)) return

    const newFieldData =
      changedField?.newValue as unknown as TicketDuplicateDetectionPayload

    if (!newFieldData?.count) return

    showTicketDuplicateDetectionDialog(newFieldData)
  }

  return {
    execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
    callback: handleTicketDuplicateDetection,
  }
}
