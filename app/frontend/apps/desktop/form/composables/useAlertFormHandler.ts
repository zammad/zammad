// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createMessage } from '@formkit/core'

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  ChangedField,
  FormHandler,
  FormHandlerFunction,
  ReactiveFormSchemaDataField,
  ReactiveFormSchemData,
} from '#shared/components/Form/types.ts'

import type { FormKitMessage, FormKitNode } from '@formkit/core'

export const useAlertFormHandler = (
  nodeName: string,
  message: Partial<FormKitMessage> & Pick<FormKitMessage, 'key'>,
  initialAddCallback: (
    field: ReactiveFormSchemaDataField,
    fields: Record<string, ReactiveFormSchemaDataField>,
  ) => boolean,
  changeAddCallback: (
    field: ChangedField | undefined,
    fields: Record<string, ReactiveFormSchemaDataField>,
  ) => boolean,
  eventHandler: (
    node: FormKitNode,
    addAlert: () => void,
    clearAlert: () => void,
  ) => void,
  eventName: string = 'input',
): FormHandler => {
  const addAlert = (formNode?: FormKitNode) => {
    formNode?.store.set(
      createMessage({
        blocking: false,
        type: 'warning',
        visible: true,
        ...message,
      }),
    )
  }

  const clearAlert = (formNode?: FormKitNode) => {
    formNode?.store.remove(message.key)
  }

  const initializeNodeEvent = (node: FormKitNode, formNode: FormKitNode) => {
    node.on(eventName, ({ origin }) => {
      eventHandler(
        origin,
        () => addAlert(formNode),
        () => clearAlert(formNode),
      )
    })
  }

  const initializeFormNodeEvents = (formNode: FormKitNode) => {
    formNode.on('child.deep', ({ payload }) => {
      const childNode = payload as FormKitNode
      if (childNode.name !== nodeName) return

      initializeNodeEvent(childNode, formNode)

      childNode.on('destroying', () => {
        clearAlert(formNode)
      })
    })
  }

  const initializeNodeEvents = (
    execution: FormHandlerExecution,
    getNodeByName: (id: string) => FormKitNode | undefined,
    formNode?: FormKitNode,
  ) => {
    if (execution === FormHandlerExecution.InitialSettled && formNode) {
      const node = getNodeByName(nodeName)

      if (node) {
        initializeNodeEvent(node, formNode)

        node.on('destroying', () => {
          clearAlert(formNode)
          initializeFormNodeEvents(formNode)
        })

        return
      }

      initializeFormNodeEvents(formNode)
    }
  }

  const executeHandler = (
    execution: FormHandlerExecution,
    schemaData: ReactiveFormSchemData,
    changedField?: ChangedField,
    formNode?: FormKitNode,
  ) => {
    if (
      schemaData.fields[nodeName] === undefined ||
      schemaData.fields[nodeName] === null ||
      (execution === FormHandlerExecution.FieldChange &&
        (!changedField || changedField.name !== nodeName)) ||
      (typeof formNode?.find === 'function' && !formNode?.find(nodeName))
    ) {
      return false
    }

    return true
  }

  const alertFormHandler: FormHandlerFunction = (
    execution,
    reactivity,
    data,
  ) => {
    const { changedField, formNode, getNodeByName } = data
    const { schemaData } = reactivity

    initializeNodeEvents(execution, getNodeByName, formNode)

    if (!executeHandler(execution, schemaData, changedField, formNode)) return

    if (
      (execution === FormHandlerExecution.InitialSettled &&
        initialAddCallback(schemaData.fields[nodeName], schemaData.fields)) ||
      (execution === FormHandlerExecution.FieldChange &&
        changeAddCallback(changedField, schemaData.fields))
    ) {
      addAlert(formNode)

      return
    }

    clearAlert(formNode)
  }

  return {
    execution: [
      FormHandlerExecution.InitialSettled,
      FormHandlerExecution.FieldChange,
    ],
    callback: alertFormHandler,
  }
}
