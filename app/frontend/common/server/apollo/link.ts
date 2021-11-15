// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { createHttpLink, from } from '@apollo/client/core'
import { setContext } from '@apollo/client/link/context'
import csrfLink from '@common/server/apollo/link/csrf'
import errorLink from '@common/server/apollo/link/error'
import debugLink from '@common/server/apollo/link/debug'

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

const httpLink = setAuthorizationLink.concat(baseLink)

const link = from([csrfLink, debugLink, errorLink, httpLink])

export default link
