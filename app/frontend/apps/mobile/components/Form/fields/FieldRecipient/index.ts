// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { print } from 'graphql'
import type { FormKitNode } from '@formkit/core'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import { AutocompleteSearchRecipientDocument } from '#shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.api.ts'
import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

export type FieldRecipientContact = 'email' | 'phone'

const gqlQuery = print(AutocompleteSearchRecipientDocument)

const setAutoCompleteBehavior = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['additionalQueryParams', 'contact', 'gqlQuery'])

  // Allow selection of unknown values, but only if they pass the validation.
  props.allowUnknownValues = true

  // Define validation of search input depending on the supplied user contact type.
  //   Include helpful hint in the search input field.
  if (props.contact === 'phone') {
    props.additionalQueryParams = {
      contact: 'phone',
    }
    props.filterInputPlaceholder = __('Search or enter phone number…')

    // Very rudimentary validator for the E.164 telephone number format, i.e. +499876543210.
    props.filterInputValidation = 'matches:/^\\+?[1-9]\\d+$/'
  } else {
    props.additionalQueryParams = {
      contact: 'email',
    }
    props.filterInputPlaceholder = __('Search or enter email address…')
    props.filterInputValidation = 'email'
  }

  props.gqlQuery = gqlQuery
}

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  [...autoCompleteProps, 'contact'],
  {
    features: [addLink, setAutoCompleteBehavior, formUpdaterTrigger()],
  },
  { addArrow: true },
)

export default {
  fieldType: 'recipient',
  definition: fieldDefinition,
}
