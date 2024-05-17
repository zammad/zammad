// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldGroupPermissionsInput from './FieldGroupPermissionsInput.vue'

const fieldDefinition = createInput(FieldGroupPermissionsInput, ['options'])

export default {
  fieldType: 'groupPermissions',
  definition: fieldDefinition,
}
