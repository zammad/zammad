// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutoComplete/types.ts'

export type AutoCompleteOrganizationOption = AutoCompleteOption & {
  organization?: Organization
}
