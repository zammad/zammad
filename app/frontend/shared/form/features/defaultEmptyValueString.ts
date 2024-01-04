// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const defaultEmptyValueString = (node: FormKitNode) => {
  node.hook.input((payload, next) => {
    if (payload === undefined) {
      return next('')
    }
    return next(payload)
  })
}

export default defaultEmptyValueString
