// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverTextarea } from '../textarea.ts'

describe('FieldResolverTextarea', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverTextarea(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'input',
        name: 'text',
        display: 'Text',
        dataOption: {
          maxlength: 100,
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Text',
      name: 'text',
      required: false,
      props: {
        maxlength: 100,
      },
      type: 'textarea',
      internal: true,
    })
  })
})
