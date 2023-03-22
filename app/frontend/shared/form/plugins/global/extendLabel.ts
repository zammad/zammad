// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'

const extendLabel = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'label', {
    attrs: {
      id: '$: "label-" + $id',
    },
  })
}

export default extendLabel
