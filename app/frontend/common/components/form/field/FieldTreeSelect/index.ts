// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldTreeSelectInput from '@common/components/form/field/FieldTreeSelect/FieldTreeSelectInput.vue'
import createInput from '@common/form/core/createInput'

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
