// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { setAutoCompleteBehavior } from '#shared/components/Form/fields/FieldRecipient/features/setAutoCompleteBehavior.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  autoCompleteProps,
  {
    features: [addLink, setAutoCompleteBehavior, formUpdaterTrigger()],
  },
  { addArrow: true },
)

export default {
  fieldType: 'recipient',
  definition: fieldDefinition,
}
