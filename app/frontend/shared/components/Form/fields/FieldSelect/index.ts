// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import FieldSelectInput from './FieldSelectInput.vue'

const hideLabelForSmallSelects = (node: FormKitNode) => {
  const { props } = node

  const toggleLabel = (isHidden: boolean) => {
    props.labelClass = isHidden ? 'hidden' : undefined
  }

  node.on('created', () => {
    toggleLabel(props.size === 'small')

    node.on('prop:size', ({ payload }) => {
      toggleLabel(payload === 'small')
    })
  })
}

const fieldDefinition = createInput(
  FieldSelectInput,
  [
    'autoselect',
    'clearable',
    'multiple',
    'noOptionsLabelTranslation',
    'options',
    'size',
    'sorting',
  ],
  {
    features: [hideLabelForSmallSelects, addLink],
  },
)

export default {
  fieldType: 'select',
  definition: fieldDefinition,
}

export type { SelectOption, SelectOptionSorting } from './types'
