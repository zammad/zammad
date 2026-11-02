// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client'
import { map } from 'rxjs'

import { setCSRFToken } from '../utils/csrfToken.ts'

const csrfLink = new ApolloLink((operation, forward) => {
  return forward(operation).pipe(
    map((response) => {
      const context = operation.getContext()

      if (context.response) {
        const csrfToken = context.response.headers.get('CSRF-Token')

        if (csrfToken) {
          setCSRFToken(csrfToken)
        }
      }
      return response
    }),
  )
})

export default csrfLink
