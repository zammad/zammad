// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

export default {
  ruleType: 'date_range',
  rule: (node: FormKitNode<string[]>) => {
    const { value } = node

    const startDate = value.at(0)
    const endDate = value.at(1)

    if (!startDate || !endDate) return false

    return startDate <= endDate
  },
  localeMessage: () => {
    return __('The start date must precede or match end date.')
  },
}
