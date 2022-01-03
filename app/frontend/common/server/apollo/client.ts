// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ApolloClient, NormalizedCacheObject } from '@apollo/client/core'
import link from '@common/server/apollo/link'
import cache from '@common/server/apollo/cache'

const apolloClient: ApolloClient<NormalizedCacheObject> = new ApolloClient({
  connectToDevTools: true,
  link,
  cache,
})

export default apolloClient
