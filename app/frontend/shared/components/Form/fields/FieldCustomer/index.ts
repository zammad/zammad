// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import FieldCustomerWrapper from './FieldCustomerWrapper.vue'
import { autoCompleteProps } from '../FieldAutoComplete'

const fieldDefinition = createInput(FieldCustomerWrapper, autoCompleteProps, {
  features: [addLink],
})

export default {
  fieldType: 'customer',
  definition: fieldDefinition,
}
