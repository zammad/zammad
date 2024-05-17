// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { hidden as hiddenDefinition } from '@formkit/inputs'

import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

initializeFieldDefinition(hiddenDefinition, {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'hidden',
  definition: hiddenDefinition,
}
