// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import FieldSelectInput from './FieldSelectInput.vue'

const hideLabelForSmallSelects = (node: FormKitNode) => {
  const { props } = node

  const toggleLabel = (isHidden: boolean) => {
    if (isHidden) {
      props.labelClass = 'hidden'
      props.arrowClass = 'hidden'
      props.outerClass = '!min-h-[initial] !p-0'
      props.wrapperClass = '!py-0'
      props.innerClass = '!p-0'
    } else {
      props.labelClass = undefined
      props.arrowClass = undefined
      props.outerClass = undefined
      props.wrapperClass = undefined
      props.innerClass = undefined
    }
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
  {
    addArrow: true,
  },
)

export default {
  fieldType: 'select',
  definition: fieldDefinition,
}

export type { SelectOption, SelectOptionSorting } from './types'
