// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage } from '@formkit/core'

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  ChangedField,
  FormHandler,
  FormHandlerFunction,
  ReactiveFormSchemData,
} from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { FormKitNode } from '@formkit/core'

export const useSSLVerificationWarningHandler = (): FormHandler => {
  const addWarning = (formNode?: FormKitNode) => {
    formNode?.store.set(
      createMessage({
        blocking: false,
        key: 'sslVerificationWarning',
        type: 'warning',
        value: i18n.t(
          'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
        ),
        visible: true,
      }),
    )
  }

  const clearWarning = (formNode?: FormKitNode) => {
    formNode?.store.remove('sslVerificationWarning')
  }

  const initializeSSLVerifyDisabledNodeEvent = (
    sslFieldNode: FormKitNode,
    formNode: FormKitNode,
  ) => {
    sslFieldNode.on('prop:disabled', ({ origin }) => {
      const { props, value } = origin

      if (props.disabled) clearWarning(formNode)
      else if (value === false) addWarning(formNode)
    })
  }

  const initializeFormNodeEvents = (formNode: FormKitNode) => {
    formNode.on('child.deep', ({ payload }) => {
      const childNode = payload as FormKitNode
      if (childNode.name !== 'sslVerify') return

      initializeSSLVerifyDisabledNodeEvent(childNode, formNode)

      childNode.on('destroying', () => {
        clearWarning(formNode)
      })
    })
  }

  const initializeSSLVerifyNodeEvents = (
    execution: FormHandlerExecution,
    getNodeByName: (id: string) => FormKitNode | undefined,
    formNode?: FormKitNode,
  ) => {
    if (execution === FormHandlerExecution.InitialSettled && formNode) {
      const sslFieldNode = getNodeByName('sslVerify')

      if (sslFieldNode) {
        initializeSSLVerifyDisabledNodeEvent(sslFieldNode, formNode)

        sslFieldNode.on('destroying', () => {
          clearWarning(formNode)
          initializeFormNodeEvents(formNode)
        })
      } else {
        initializeFormNodeEvents(formNode)
      }
    }
  }

  const executeHandler = (
    execution: FormHandlerExecution,
    schemaData: ReactiveFormSchemData,
    changedField?: ChangedField,
    formNode?: FormKitNode,
  ) => {
    if (
      schemaData.fields.sslVerify === undefined ||
      schemaData.fields.sslVerify === null ||
      (execution === FormHandlerExecution.FieldChange &&
        (!changedField || changedField.name !== 'sslVerify')) ||
      (typeof formNode?.find === 'function' && !formNode?.find('sslVerify'))
    ) {
      return false
    }

    return true
  }

  const handleSSLVerificationWarning: FormHandlerFunction = (
    execution,
    reactivity,
    data,
  ) => {
    const { changedField, formNode, getNodeByName } = data
    const { schemaData } = reactivity

    initializeSSLVerifyNodeEvents(execution, getNodeByName, formNode)

    if (!executeHandler(execution, schemaData, changedField, formNode)) return

    if (
      !schemaData.fields.sslVerify.props.disabled &&
      ((execution === FormHandlerExecution.InitialSettled &&
        schemaData.fields.sslVerify.props.value === false) ||
        (execution === FormHandlerExecution.FieldChange &&
          changedField?.newValue === false))
    ) {
      addWarning(formNode)

      return
    }

    clearWarning(formNode)
  }

  return {
    execution: [
      FormHandlerExecution.InitialSettled,
      FormHandlerExecution.FieldChange,
    ],
    callback: handleSSLVerificationWarning,
  }
}
