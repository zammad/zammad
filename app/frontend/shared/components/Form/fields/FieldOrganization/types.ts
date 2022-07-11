// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar/types'
import type { AutoCompleteOption } from '@shared/components/Form/fields/FieldAutoComplete/types'

export type AutoCompleteOrganizationOption = AutoCompleteOption & {
  // TODO: surely, there should be a better type for this?
  organization?: AvatarOrganization
}
