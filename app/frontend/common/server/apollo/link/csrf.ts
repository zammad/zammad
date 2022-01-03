// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'

const csrfLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    const context = operation.getContext()

    if (context.response) {
      const csrfToken = context.response.headers.get('CSRF-Token')

      if (csrfToken) {
        localStorage.setItem('csrf-token', csrfToken) // TODO move to a different solution. only for now...
      }
    }
    return response
  })
})

export default csrfLink
