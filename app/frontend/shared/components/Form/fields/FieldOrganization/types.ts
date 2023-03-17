// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '@shared/graphql/types'
import type { AutoCompleteOption } from '@shared/components/Form/fields/FieldAutoComplete/types'

export type AutoCompleteOrganizationOption = AutoCompleteOption & {
  organization?: Organization
}
