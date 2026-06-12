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
    // Route field errors to the matching node. Try a depth-first name search
    // first (handles fields nested inside FormKit group nodes, e.g. multi-step
    // forms), then fall back to node.at() for dot-path addresses like
    // "inbound.adapter". Errors that cannot be resolved to a field node are
    // promoted to form-level errors so they are never silently dropped.
    const unresolvedErrors: string[] = []

    Object.entries(errors.getFieldErrorList()).forEach(([fieldName, message]) => {
      const fieldNode = node.find(fieldName, 'name') ?? node.at(fieldName)
      if (fieldNode && fieldNode !== node) {
        fieldNode.setErrors([message])
      } else {
        unresolvedErrors.push(message)
      }
    })

    node.setErrors([...(errors.generalErrors as string[]), ...unresolvedErrors])
    return
  }

  node.setErrors(errors?.message || __('An unexpected error has occurred.'))
}
