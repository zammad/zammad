// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { setAutoCompleteBehavior } from '#shared/components/Form/fields/FieldRecipient/features/setAutoCompleteBehavior.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import type { FormKitNode } from '@formkit/core'

const setFilterProps = (node: FormKitNode) => {
  const { props } = node

  // Define validation of search input depending on the supplied user contact type.
  //   Include helpful hint in the search input field.
  if (props.contact === 'phone') {
    props.filterInputPlaceholder = __('Search or enter phone number…')

    // Very rudimentary validator for the E.164 telephone number format, i.e. +499876543210.
    props.filterInputValidation = 'matches:/^\\+?[1-9]\\d+$/'
  } else {
    props.filterInputPlaceholder = __('Search or enter email address…')
    props.filterInputValidation = 'email'
  }
}

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  autoCompleteProps,
  {
    features: [
      addLink,
      setAutoCompleteBehavior,
      setFilterProps,
      formUpdaterTrigger(),
    ],
  },
  { addArrow: true },
)

export default {
  fieldType: 'recipient',
  definition: fieldDefinition,
}
