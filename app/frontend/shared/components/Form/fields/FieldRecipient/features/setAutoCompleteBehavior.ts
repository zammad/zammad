// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { print } from 'graphql'

import { AutocompleteSearchRecipientDocument } from '#shared/components/Form/fields/FieldRecipient/graphql/queries/autocompleteSearch/recipient.api.ts'

import { emailFilterValueValidator, phoneFilterValueValidator } from './filterValueValidators.ts'

import type { FormKitNode } from '@formkit/core'

const gqlQuery = print(AutocompleteSearchRecipientDocument)

export const setAutoCompleteBehavior = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['contact', 'gqlQuery'])

  // Allow selection of unknown values, but only if they pass the validation.
  props.allowUnknownValues = true

  // Define validation of search input depending on the supplied user contact type.
  //   Include helpful hint in the search input field.
  if (props.contact === 'phone') {
    props.additionalQueryParams = {
      contact: 'phone',
    }
    props.filterInputPlaceholder = __('Search or enter phone number…')
    props.filterValueValidator = phoneFilterValueValidator
  } else {
    props.additionalQueryParams = {
      contact: 'email',
    }
    props.filterInputPlaceholder = __('Search or enter email address…')
    props.filterValueValidator = emailFilterValueValidator
  }

  props.gqlQuery = gqlQuery
}
