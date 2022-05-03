// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@common/form/core/createInput'
import FieldFileInput from '@common/components/form/field/FieldFile/FieldFileInput.vue'

const fieldDefinition = createInput(
  FieldFileInput,
  ['multiple', 'capture', 'accept'],
  {},
)

export default {
  fieldType: 'file',
  definition: fieldDefinition,
}
