// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import defaultEmptyValueString from '#shared/form/features/defaultEmptyValueString.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldEditorWrapper from './FieldEditorWrapper.vue'

const fieldDefinition = createInput(
  FieldEditorWrapper,
  ['groupId', 'ticketId', 'customerId', 'meta', 'contentType'],
  {
    features: [formUpdaterTrigger('delayed', 500), defaultEmptyValueString],
  },
)

export default {
  fieldType: 'editor',
  definition: fieldDefinition,
}
