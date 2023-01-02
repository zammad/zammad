// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import UserError from '../UserError'

const errors = [
  {
    message: 'A problem example.',
  },
  {
    field: 'title',
    message: 'A problem with the title.',
  },
]

const userError = new UserError(errors)

describe('UserError', () => {
  it('should construct itself correctly', () => {
    expect(userError.generalErrors).toEqual(['A problem example.'])
    expect(userError.fieldErrors).toEqual([
      { field: 'title', message: 'A problem with the title.' },
    ])
  })

  it('get field error list', () => {
    expect(userError.getFieldErrorList()).toEqual({
      title: 'A problem with the title.',
    })
  })
})
