// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldToggleButtonsInput from './FieldToggleButtonsInput.vue'

const fieldDefinition = createInput(FieldToggleButtonsInput, ['options'], {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'toggleButtons',
  definition: fieldDefinition,
}
