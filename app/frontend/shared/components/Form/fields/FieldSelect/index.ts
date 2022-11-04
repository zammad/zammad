// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'
import { FormSchemaExtendType } from '@shared/types/form'
import FieldSelectInput from './FieldSelectInput.vue'

const hideLabelForSmallSelects = (node: FormKitNode) => {
  extendSchemaDefinition(
    node,
    'outer',
    {
      attrs: {
        'data-label-hidden': {
          if: '$size == "small"',
          then: 'true',
          else: undefined,
        },
      },
    },
    FormSchemaExtendType.Merge,
  )
}

const fieldDefinition = createInput(
  FieldSelectInput,
  [
    'clearable',
    'multiple',
    'noOptionsLabelTranslation',
    'options',
    'size',
    'sorting',
  ],
  {
    features: [hideLabelForSmallSelects, addLink, formUpdaterTrigger()],
  },
  {
    addArrow: true,
  },
)

export default {
  fieldType: 'select',
  definition: fieldDefinition,
}

export type { SelectOption, SelectOptionSorting, SelectValue } from './types'
