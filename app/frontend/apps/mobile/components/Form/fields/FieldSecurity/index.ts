// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldSecurityInput from './FieldSecurityInput.vue'

const fieldDefinition = createInput(FieldSecurityInput, [
  'securityAllowed',
  'securityDefaultOptions',
  'securityMessages',
])

export default {
  fieldType: 'security',
  definition: fieldDefinition,
}
