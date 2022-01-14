// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { setContext } from '@apollo/client/link/context'
import { getCSRFToken } from '@common/server/apollo/utils/csrfToken'

const setAuthorizationLink = setContext((request, { headers }) => ({
  headers: {
    ...headers,

    // Fetch CSRF from head via html embed from Rails.
    'X-CSRF-Token': getCSRFToken(),
  },
}))

export default setAuthorizationLink
