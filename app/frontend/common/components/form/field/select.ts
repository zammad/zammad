// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeFieldDefinition from '@common/form/core/initializeFieldDefinition'
import { select as selectDefinition } from '@formkit/inputs'

initializeFieldDefinition(selectDefinition)

export default {
  fieldType: 'select',
  definition: selectDefinition,
}
