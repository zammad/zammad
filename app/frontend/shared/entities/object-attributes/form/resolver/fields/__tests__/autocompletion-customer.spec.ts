// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverAutocompletionCustomer } from '../autocompletion-customer.ts'

describe('FieldResolverAutocompletionCustomer', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverAutocompletionCustomer(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'user_autocempletion',
        name: 'customer',
        display: 'Customer',
        dataOption: {
          belongs_to: 'customer',
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Customer',
      name: 'customer',
      required: false,
      props: {
        belongsToObjectField: 'customer',
        clearable: true,
        noOptionsLabelTranslation: true,
      },
      type: 'customer',
      internal: true,
    })
  })
})
