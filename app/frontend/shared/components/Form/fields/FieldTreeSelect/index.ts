// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldTreeSelectInput from '@shared/components/Form/fields/FieldTreeSelect/FieldTreeSelectInput.vue'
import createInput from '@shared/form/core/createInput'

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

export type { FlatSelectOption } from '@shared/components/Form/fields/FieldTreeSelect/types'
