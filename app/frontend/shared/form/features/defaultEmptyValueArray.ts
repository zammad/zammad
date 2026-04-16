// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const defaultEmptyValueArray = (node: FormKitNode) => {
  node.hook.input((payload, next) => {
    if ((payload === undefined || payload === null) && node.props.multiple) {
      return next([])
    }
    return next(payload)
  })
}

export default defaultEmptyValueArray
