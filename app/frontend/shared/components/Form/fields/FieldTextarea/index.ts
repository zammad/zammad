// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { textarea as textareaDefinition } from '@formkit/inputs'

import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import defaultEmptyValueString from '#shared/form/features/defaultEmptyValueString.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import { textareaInput } from '#shared/form/sections/textareaInput.ts'

initializeFieldDefinition(
  textareaDefinition,
  {
    features: [formUpdaterTrigger('delayed'), defaultEmptyValueString],
  },
  { schema: textareaInput },
)

// TODO resizing as prop?

export default {
  fieldType: 'textarea',
  definition: textareaDefinition,
}
