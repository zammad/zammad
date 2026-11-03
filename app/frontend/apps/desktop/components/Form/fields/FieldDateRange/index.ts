// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import healDateRange from '#shared/components/Form/fields/FieldDate/healDateRange.ts'
import normalizeDateValue from '#shared/components/Form/fields/FieldDate/normalizeDateValue.ts'
import { dateRangeFieldProps } from '#shared/components/Form/fields/FieldDateRange/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldDateRangeInput from './FieldDateRangeInput.vue'

const fieldDefinition = createInput(FieldDateRangeInput, dateRangeFieldProps, {
  features: [addLink, formUpdaterTrigger(), normalizeDateValue, healDateRange],
})

export default {
  fieldType: 'daterange',
  definition: fieldDefinition,
}
