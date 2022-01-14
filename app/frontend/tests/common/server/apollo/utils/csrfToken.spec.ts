// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const initialCSRFToken = '1234567890ABC'

const metaElement = document.createElement('meta')
metaElement.setAttribute('name', 'csrf-token')
metaElement.setAttribute('content', initialCSRFToken)

jest.spyOn(document, 'querySelector').mockImplementation((): Element => {
  return metaElement
})

// Special situation where we need to use the import statement after the document meta data mock, because
// otherwise the initial csrf token is not set.
// eslint-disable-next-line import/first
import {
  getCSRFToken,
  setCSRFToken,
} from '@common/server/apollo/utils/csrfToken'

describe('csrfToken handling', () => {
  it('get initial token', () => {
    expect(getCSRFToken()).toEqual(initialCSRFToken)
  })

  it('set crsf token and check if this will be returned', () => {
    const otherValue = 'other-123456789'

    setCSRFToken(otherValue)

    expect(getCSRFToken()).toEqual(otherValue)
  })
})
