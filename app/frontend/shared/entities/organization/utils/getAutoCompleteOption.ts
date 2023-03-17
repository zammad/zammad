// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '@shared/graphql/types'
import { ensureGraphqlId } from '@shared/graphql/utils'

export const getAutoCompleteOption = (organization: Partial<Organization>) => {
  return {
    label: organization.name,
    value:
      organization.internalId ||
      (organization.id
        ? ensureGraphqlId('Organization', organization.id)
        : null),
    organization,
  }
}
