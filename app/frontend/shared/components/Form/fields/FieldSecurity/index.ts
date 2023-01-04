// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import FieldSecurity from './FieldSecurity.vue'

const fieldDefinition = createInput(FieldSecurity, ['allowed'])

export default {
  fieldType: 'security',
  definition: fieldDefinition,
}
