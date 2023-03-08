// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import removeValuesForNonExistingOptions from '@shared/form/features/removeValuesForNonExistingOptions'
import FieldSelectInput from './FieldSelectInput.vue'

const fieldDefinition = createInput(
  FieldSelectInput,
  [
    'clearable',
    'historicalOptions',
    'multiple',
    'noOptionsLabelTranslation',
    'options',
    'rejectNonExistentValues',
    'sorting',
  ],
  {
    features: [
      addLink,
      formUpdaterTrigger(),
      removeValuesForNonExistingOptions,
    ],
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
