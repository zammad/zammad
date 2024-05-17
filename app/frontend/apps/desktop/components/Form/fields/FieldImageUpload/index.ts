// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldImageUploadInput from './FieldImageUploadInput.vue'

const fieldDefinition = createInput(FieldImageUploadInput, [
  'placeholderImagePath',
])

export default {
  fieldType: 'imageUpload',
  definition: fieldDefinition,
}
