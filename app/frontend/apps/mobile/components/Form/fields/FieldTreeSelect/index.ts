// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import removeValuesForNonExistingOrDisabledOptions from '#shared/form/features/removeValuesForNonExistingOrDisabledOptions.ts'
import FieldTreeSelectInput from './FieldTreeSelectInput.vue'

const fieldDefinition = createInput(
  FieldTreeSelectInput,
  [
    'clearable',
    'historicalOptions',
    'multiple',
    'noFiltering',
    'noOptionsLabelTranslation',
    'options',
    'rejectNonExistentValues',
    'sorting',
  ],
  {
    features: [
      addLink,
      formUpdaterTrigger(),
      removeValuesForNonExistingOrDisabledOptions,
    ],
  },
  { addArrow: true },
)

export default {
  fieldType: 'treeselect',
  definition: fieldDefinition,
}
