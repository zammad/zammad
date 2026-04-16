// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const defaultEmptyValue = (node: FormKitNode) => {
  node.hook.input((payload, next) => {
    if (payload === undefined || payload === null) {
      return next(node.props.multiple ? [] : '')
    }
    return next(payload)
  })
}

export default defaultEmptyValue
