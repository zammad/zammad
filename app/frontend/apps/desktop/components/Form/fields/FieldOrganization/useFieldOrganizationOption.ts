// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import type { AutoCompleteOrganizationOption } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import type { Organization } from '#shared/graphql/types.ts'

export const useFieldOrganizationOption = (
  organization: Organization,
): AutoCompleteOrganizationOption => ({
  value: organization.internalId,
  label: organization.name as string,
  organization,
})
