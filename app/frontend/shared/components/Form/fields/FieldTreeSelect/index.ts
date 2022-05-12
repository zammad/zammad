// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import FieldTreeSelectInput from './FieldTreeSelectInput.vue'

const fieldDefinition = createInput(FieldTreeSelectInput, [
  'autoselect',
  'clearable',
  'noFiltering',
  'multiple',
  'noOptionsLabelTranslation',
  'options',
  'sorting',
])

export default {
  fieldType: 'treeselect',
  definition: fieldDefinition,
}

export type { FlatSelectOption } from './types'
