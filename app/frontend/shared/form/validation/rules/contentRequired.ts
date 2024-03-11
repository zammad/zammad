// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

export default {
  ruleType: 'content_required',
  rule: (node: FormKitNode<string>, ...args: string[]) => {
    const isNodeValueDefined = !!node.value?.trim()
    const parentValues = node.parent?.value as Record<string, string>
    if (isNodeValueDefined) return true
    if (!parentValues) return false

    return args.some((validationKey) => {
      const value = parentValues[validationKey]
      return !!value
    })
  },
  localeMessage: () => {
    return __('Text or Attachment is required.')
  },
}
