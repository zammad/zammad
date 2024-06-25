// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
})
