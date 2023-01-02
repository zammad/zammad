// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarUser } from '@shared/components/CommonUserAvatar/types'
import type { AutoCompleteOption } from '@shared/components/Form/fields/FieldAutoComplete/types'

export type AutoCompleteCustomerOption = AutoCompleteOption & {
  user?: AvatarUser
}
