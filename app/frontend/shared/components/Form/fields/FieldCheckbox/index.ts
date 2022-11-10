// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { checkbox as checkboxDefinition } from '@formkit/inputs'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'

initializeFieldDefinition(checkboxDefinition, {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'checkbox',
  definition: checkboxDefinition,
}
