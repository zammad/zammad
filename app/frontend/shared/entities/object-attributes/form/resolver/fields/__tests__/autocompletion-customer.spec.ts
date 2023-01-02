// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverAutocompletionCustomer } from '../autocompletion-customer'

describe('FieldResolverAutocompletionCustomer', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverAutocompletionCustomer({
      dataType: 'user_autocempletion',
      name: 'customer',
      display: 'Customer',
      dataOption: {
        belongs_to: 'customer',
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Customer',
      name: 'customer',
      required: false,
      props: {
        belongsToObjectField: 'customer',
        noOptionsLabelTranslation: true,
      },
      type: 'customer',
      internal: true,
    })
  })
})
