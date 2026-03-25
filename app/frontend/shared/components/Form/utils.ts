// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, getNode, type FormKitMessage, type FormKitNode } from '@formkit/core'

import UserError from '#shared/errors/UserError.ts'

import type { MutationSendError } from '../../types/error.ts'

export const getNodeId = (formId: string, selector: string) => {
  return `${selector}-${formId}`
}

export const getNodeByName = (formId: string, selector: string) => {
  return getNode(getNodeId(formId, selector))
}

export const setMessage = (
  node: FormKitNode,
  message: Partial<FormKitMessage> & Pick<FormKitMessage, 'key'>,
) => {
  node.store.set(
    createMessage({
      blocking: false,
      type: 'warning',
      visible: true,
      ...message,
    }),
  )
}

export const clearMessage = (node: FormKitNode, key: string) => {
  node.store.remove(key)
}

export const setErrors = (node: FormKitNode, errors: MutationSendError) => {
  if (errors instanceof UserError) {
    node.setErrors(errors.generalErrors as string[], errors.getFieldErrorList())
    return
  }

  node.setErrors(errors?.message || __('An unexpected error has occurred.'))
}
