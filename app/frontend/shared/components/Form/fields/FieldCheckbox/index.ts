// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { checkbox as checkboxDefinition } from '@formkit/inputs'
import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'

const addCheckedDataAttribute = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      'data-is-checked': {
        if: '$value',
        then: 'true',
        else: undefined,
      },
      'data-test-id': 'checkbox-label',
    },
  })
}

initializeFieldDefinition(checkboxDefinition, {
  features: [addCheckedDataAttribute, formUpdaterTrigger()],
})

export default {
  fieldType: 'checkbox',
  definition: checkboxDefinition,
}
