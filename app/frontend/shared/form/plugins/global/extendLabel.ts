// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'

import type { FormKitNode } from '@formkit/core'

const extendLabel = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'label', {
    attrs: {
      id: '$: "label-" + $id',
    },
  })
}

export default extendLabel
