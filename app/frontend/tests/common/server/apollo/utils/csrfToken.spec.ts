// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import '@tests/support/mock-hoist-helper'
import {
  getCSRFToken,
  setCSRFToken,
} from '@common/server/apollo/utils/csrfToken'

const setMetaElement = () => {
  const metaElement = document.createElement('meta')
  metaElement.setAttribute('name', 'csrf-token')
  metaElement.setAttribute('content', '1234567890ABC')

  jest.spyOn(document, 'querySelector').mockImplementation((): Element => {
    return metaElement
  })
}

jest.mock('@tests/support/mock-hoist-helper', () => {
  setMetaElement()
})

describe('csrfToken handling', () => {
  it('get initial token', () => {
    expect(getCSRFToken()).toEqual('1234567890ABC')
  })

  it('set crsf token and check if this will be returned', () => {
    const otherValue = 'other-123456789'

    setCSRFToken(otherValue)

    expect(getCSRFToken()).toEqual(otherValue)
  })
})
