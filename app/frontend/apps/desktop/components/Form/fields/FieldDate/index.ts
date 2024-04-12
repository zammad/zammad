// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'
import { dateFieldProps } from '#shared/components/Form/fields/FieldDate/types.ts'
import FieldDateTimeInput from './FieldDateTimeInput.vue'

const prefixLabelForAttribute = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'label', {
    attrs: {
      for: '$: "dp-input-" + $id',
    },
  })
}

const dateFieldDefinition = createInput(FieldDateTimeInput, dateFieldProps, {
  features: [addLink, formUpdaterTrigger(), prefixLabelForAttribute],
})

export default [
  {
    fieldType: 'date',
    definition: dateFieldDefinition,
  },
  {
    fieldType: 'datetime',
    definition: dateFieldDefinition,
  },
]
