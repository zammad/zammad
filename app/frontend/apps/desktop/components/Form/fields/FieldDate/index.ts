// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import normalizeDateValue from '#shared/components/Form/fields/FieldDate/normalizeDateValue.ts'
import { dateFieldProps } from '#shared/components/Form/fields/FieldDate/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldDateInput from './FieldDateInput.vue'

const dateFieldDefinition = createInput(FieldDateInput, dateFieldProps, {
  features: [addLink, formUpdaterTrigger(), normalizeDateValue],
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
