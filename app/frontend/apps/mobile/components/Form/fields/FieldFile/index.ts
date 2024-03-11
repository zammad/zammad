// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import FieldFileInput from '#mobile/components/Form/fields/FieldFile/FieldFileInput.vue'
import { multipleFilesError } from './features/multipleFilesError.ts'

const fieldDefinition = createInput(
  FieldFileInput,
  ['multiple', 'capture', 'accept'],
  {
    features: [multipleFilesError],
  },
)

export default {
  fieldType: 'file',
  definition: fieldDefinition,
}
