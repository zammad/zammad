import { ApolloClient, NormalizedCacheObject } from '@apollo/client/core'
import link from '@common/server/apollo/link'
import cache from '@common/server/apollo/cache'

const apolloClient: ApolloClient<NormalizedCacheObject> = new ApolloClient({
  connectToDevTools: true,
  link,
  cache,
})

export default apolloClient
