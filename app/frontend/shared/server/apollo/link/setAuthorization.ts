// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { SetContextLink } from '@apollo/client/link/context'

import { getCSRFToken } from '../utils/csrfToken.ts'

const setAuthorizationLink = new SetContextLink(({ headers }) => ({
  headers: {
    ...headers,

    // Fetch CSRF from head via html embed from Rails.
    'X-CSRF-Token': getCSRFToken(),
  },
}))

export default setAuthorizationLink
