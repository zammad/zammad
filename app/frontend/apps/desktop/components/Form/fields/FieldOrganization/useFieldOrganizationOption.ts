// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import type { AutoCompleteOrganizationOption } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import type { Organization } from '#shared/graphql/types.ts'

export const useFieldOrganizationOption = (
  organization: Organization,
): AutoCompleteOrganizationOption => ({
  __typename: 'AutocompleteSearchOrganizationEntry',
  value: organization.internalId,
  label: organization.name as string,
  labelPlaceholder: null,
  heading: null,
  headingPlaceholder: null,
  disabled: false,
  icon: null,
  organization: {
    __typename: 'Organization',
    id: organization.id,
    internalId: organization.internalId,
    name: organization.name,
    shared: organization.shared,
    domain: organization.domain,
    domainAssignment: organization.domainAssignment,
    active: organization.active,
    note: organization.note,
    vip: organization.vip,
    objectAttributeValues: organization.objectAttributeValues?.map(
      ({ attribute, value, renderedLink }) => ({
        __typename: 'ObjectAttributeValue',
        value,
        renderedLink,
        attribute: {
          __typename: 'ObjectManagerFrontendAttribute',
          name: attribute.name,
          display: attribute.display,
        },
      }),
    ),
  },
})
