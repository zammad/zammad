// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import log from '@common/utils/log'

// TODO: only a start, needs to be extended...
// - Generic error handling for submit handlers
// - ...
const useForm = (formId: string) => {
  const formNode = getNode(formId)

  if (!formNode) {
    log.error(`Form with id "${formId}" not found`)
  }

  return {
    formNode,
  }
}

export default useForm
