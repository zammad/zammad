// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldNotificationsInput from './FieldNotificationsInput.vue'

const fieldDefinition = createInput(FieldNotificationsInput, [], {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'notifications',
  definition: fieldDefinition,
}
