// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverAutocompletionCustomerOrganization } from '../autocompletion-customer-organization.ts'

describe('FieldResolverAutocompletionCustomerOrganization', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverAutocompletionCustomerOrganization(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'user_autocempletion',
        name: 'organization',
        display: 'Organization',
        dataOption: {
          belongs_to: 'organization',
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Organization',
      name: 'organization',
      required: false,
      props: {
        belongsToObjectField: 'organization',
        clearable: true,
        noOptionsLabelTranslation: true,
      },
      type: 'organization',
      internal: true,
    })
  })

  it('exposes the is operator and organization autocomplete for advanced filters', () => {
    const fieldResolver = new FieldResolverAutocompletionCustomerOrganization(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'autocompletion_ajax_customer_organization',
        name: 'organization_id',
        display: 'Organization',
        // The autocomplete picker is derived from the relation via the
        // FieldResolver default — this resolver only declares the operator.
        dataOption: { relation: 'Organization' },
        isInternal: true,
      },
    )

    expect(fieldResolver.getFieldFilterOperators()).toEqual(['is'])
    expect(fieldResolver.getFilterAutocompleteType()).toBe('organization')
    expect(fieldResolver.getFilterRelation()).toBe('Organization')
  })
})
