// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import { autoCompleteProps } from '../FieldAutoComplete'

const setAutoCompleteBehavior = (node: FormKitNode) => {
  const { props } = node

  // Allow selection of unknown values, but only if they pass email validation.
  //   Include helpful hint in the search input field.
  props.allowUnknownValues = true
  props.filterInputPlaceholder = __('Search or enter email address…')
  props.filterInputValidation = 'email'

  node.addProps(['gqlQuery'])

  props.gqlQuery = `
  query autocompleteSearchRecipient($query: String!, $limit: Int) {
    autocompleteSearchRecipient(query: $query, limit: $limit) {
      value
      label
      labelPlaceholder
      heading
      headingPlaceholder
      disabled
      icon
    }
  }
  `
}

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
