// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { textarea as textareaDefinition } from '@formkit/inputs'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'

initializeFieldDefinition(textareaDefinition, {
  features: [formUpdaterTrigger('delayed')],
})

// TODO resizing as prop?

export default {
  fieldType: 'textarea',
  definition: textareaDefinition,
}
