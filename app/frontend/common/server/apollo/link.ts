// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { createHttpLink, ApolloLink, from } from '@apollo/client/core'
import { setContext } from '@apollo/client/link/context'

const baseLink = createHttpLink({
  uri: '/graphql',

  // Must have for CSRF validation via Rails.
  credentials: 'same-origin',
})

const csrfTokenMetaElement: Maybe<HTMLMetaElement> = document.querySelector(
  'meta[name="csrf-token"]',
)
const initialCsrfToken = csrfTokenMetaElement
  ? csrfTokenMetaElement.getAttribute('content')
  : null
const getCsrfToken = (): Maybe<string> => {
  return localStorage.getItem('csrf-token') || initialCsrfToken
}

const setAuthorizationLink = setContext((request, { headers }) => ({
  headers: {
    ...headers,
    // Fetch CSRF from head via html embed from Rails.
    'X-CSRF-Token': getCsrfToken(),
  },
}))

const afterwareLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    const context = operation.getContext()
    const {
      response: { headers },
    } = context

    if (headers) {
      const csrfToken = headers.get('CSRF-Token')

      if (csrfToken) {
        localStorage.setItem('csrf-token', csrfToken) // TODO move to a different solution. only for now...
      }
    }
    return response
  })
})

const httpLink = setAuthorizationLink.concat(baseLink)

const link = from([afterwareLink, httpLink])

export default link
