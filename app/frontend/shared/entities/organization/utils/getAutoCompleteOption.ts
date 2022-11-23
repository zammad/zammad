// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '@shared/graphql/types'

export const getAutoCompleteOption = (organization: Partial<Organization>) => {
  return {
    label: organization.name,
    value: organization.internalId,
    // disabled: !object.active, // TODO: we can not use disabled for the active/inactive flag, because it will be no longer possible to select the option
    organization,
  }
}
