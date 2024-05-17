// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode, type FormKitNode } from '@formkit/core'

import UserError from '#shared/errors/UserError.ts'

import type { MutationSendError } from '../../types/error.ts'

export const getNodeId = (formId: string, selector: string) => {
  return `${selector}-${formId}`
}

export const getNodeByName = (formId: string, selector: string) => {
  return getNode(getNodeId(formId, selector))
}

export const setErrors = (node: FormKitNode, errors: MutationSendError) => {
  // TODO: we need to check if translations are working as expected for this errors here.
  // TODO: we need to check/style the general error output when we want to show it related to the form.
  if (errors instanceof UserError) {
    node.setErrors(errors.generalErrors as string[], errors.getFieldErrorList())
  } else {
    node.setErrors(__('An unexpected error has occurred.'))
  }
}
