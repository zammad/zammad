// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutoCompleteProps } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { AutocompleteSearchOrganizationQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type AutoCompleteOrganizationOption = ConfidentTake<
  AutocompleteSearchOrganizationQuery,
  'autocompleteSearchOrganization'
>[number]

export interface AutocompleteOrganizationProps {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteOrganizationOption[]
    }
  >
}
