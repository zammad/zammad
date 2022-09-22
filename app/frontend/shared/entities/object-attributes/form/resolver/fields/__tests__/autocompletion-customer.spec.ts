// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverAutocompletionCustomer } from '../autocompletion-customer'

describe('FieldResolverAutocompletionCustomer', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverAutocompletionCustomer({
      dataType: 'user_autocempletion',
      name: 'customer',
      display: 'Customer',
      dataOption: {
        // TODO ...
      },
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Customer',
      name: 'customer',
      props: {},
      type: 'customer',
    })
  })
})
