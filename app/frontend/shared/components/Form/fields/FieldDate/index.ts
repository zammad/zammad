// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import FieldDateTimeInput from './FieldDateTimeInput.vue'

const props = ['maxDate', 'minDate', 'futureOnly', 'link']

const dateFieldDefinition = createInput(FieldDateTimeInput, props, {
  features: [formUpdaterTrigger()],
})

export default [
  {
    fieldType: 'date',
    definition: dateFieldDefinition,
  },
  {
    fieldType: 'datetime',
    definition: dateFieldDefinition,
  },
]
