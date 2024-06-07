// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { setAutoCompleteBehavior } from '#shared/components/Form/fields/FieldRecipient/features/setAutoCompleteBehavior.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldRecipientWrapper from './FieldRecipientWrapper.vue'

const fieldDefinition = createInput(FieldRecipientWrapper, autoCompleteProps, {
  features: [addLink, setAutoCompleteBehavior, formUpdaterTrigger()],
})

export default {
  fieldType: 'recipient',
  definition: fieldDefinition,
}
