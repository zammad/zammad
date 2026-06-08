// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

export const getAutoCompleteOption = (organization: Partial<Organization>) => {
  return {
    label: organization.name,
    value: organization.internalId || getIdFromGraphQLId(organization.id as string),
    organization,
  }
}
