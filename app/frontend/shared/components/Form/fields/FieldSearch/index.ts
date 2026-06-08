// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldSearchInput from './FieldSearchInput.vue'

const fieldDefinition = createInput(FieldSearchInput, ['noBorder'])

export default {
  fieldType: 'search',
  definition: fieldDefinition,
}
