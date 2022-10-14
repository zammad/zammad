// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import getFieldFromAttribute from '../getFieldFromAttribute'

describe('object attribute correctly resolved as field schema', () => {
  it('should return the correct field schema', () => {
    const fieldSchema = getFieldFromAttribute({
      dataType: 'input',
      name: 'title',
      display: 'Title',
      dataOption: {
        type: 'text',
        maxlength: 100,
      },
      isInternal: true,
    })

    expect(fieldSchema).toEqual({
      label: 'Title',
      name: 'title',
      props: {
        maxlength: 100,
      },
      type: 'text',
    })
  })
})
