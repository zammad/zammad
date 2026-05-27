// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldCustomerWrapper from './FieldCustomerWrapper.vue'

const fieldDefinition = createInput(
  FieldCustomerWrapper,
  [...autoCompleteProps, 'allowUnknownEmail'],
  {
    features: [addLink, formUpdaterTrigger()],
  },
)

export default {
  fieldType: 'customer',
  definition: fieldDefinition,
}
