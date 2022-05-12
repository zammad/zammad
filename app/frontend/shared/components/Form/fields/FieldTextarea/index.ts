// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { textarea as textareaDefinition } from '@formkit/inputs'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'

initializeFieldDefinition(textareaDefinition)

// TODO resizing as prop?

export default {
  fieldType: 'textarea',
  definition: textareaDefinition,
}
