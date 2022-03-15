// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@common/form/core/initializeFieldDefinition'
import { checkbox as checkboxDefinition } from '@formkit/inputs'

initializeFieldDefinition(checkboxDefinition)

export default {
  fieldType: 'checkbox',
  definition: checkboxDefinition,
}
