// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { setContext } from '@apollo/client/link/context'

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

export default setAuthorizationLink
