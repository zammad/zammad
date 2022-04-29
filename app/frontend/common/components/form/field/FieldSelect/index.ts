// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldSelectInput from '@common/components/form/field/FieldSelect/FieldSelectInput.vue'
import createInput from '@common/form/core/createInput'
import type { FormKitNode } from '@formkit/core'

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
    features: [hideLabelForSmallSelects],
  },
)

export default {
  fieldType: 'select',
  definition: fieldDefinition,
}
