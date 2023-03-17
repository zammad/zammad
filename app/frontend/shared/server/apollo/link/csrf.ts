// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'
import { setCSRFToken } from '../utils/csrfToken'

const csrfLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    const context = operation.getContext()

    if (context.response) {
      const csrfToken = context.response.headers.get('CSRF-Token')

      if (csrfToken) {
        setCSRFToken(csrfToken)
      }
    }
    return response
  })
})

export default csrfLink
