// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Operation } from '@apollo/client/core'
import { ApolloLink, createHttpLink, from } from '@apollo/client/core'
import type { FragmentDefinitionNode, OperationDefinitionNode } from 'graphql'
import consumer from '@shared/server/action_cable/consumer'
import { BatchHttpLink } from '@apollo/client/link/batch-http'
import { getMainDefinition } from '@apollo/client/utilities'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'
import csrfLink from './link/csrf'
import errorLink from './link/error'
import testFlagsLink from './link/testFlags'
import debugLink from './link/debug'
import setAuthorizationLink from './link/setAuthorization'
import connectedStateLink from './link/connectedState'

// Should subsequent HTTP calls be batched together?
const enableBatchLink = true

// Should queries and mutations be sent over ActionCable?
const enableQueriesOverWebsocket = false

const connectionSettings = {
  uri: '/graphql',
  credentials: 'same-origin', // Must have for CSRF validation via Rails.
}

const noBatchLink = createHttpLink(connectionSettings)

const batchLink = new BatchHttpLink({
  ...connectionSettings,
  batchMax: 5,
  batchInterval: 20,
})

const operationIsLoginLogout = (
  definition: OperationDefinitionNode | FragmentDefinitionNode,
) => {
  return !!(
    definition.kind === 'OperationDefinition' &&
    definition.operation === 'mutation' &&
    definition.name?.value &&
    ['login', 'logout'].includes(definition.name?.value)
  )
}

// TODO: Maybe we can also add a generic solution with the query context to exclude operation for batching or
// run operations over websocket.
const operationIsFormUpdater = (
  definition: OperationDefinitionNode | FragmentDefinitionNode,
) => {
  return !!(
    definition.kind === 'OperationDefinition' &&
    definition.operation === 'query' &&
    definition.name?.value &&
    definition.name?.value === 'formUpdater'
  )
}

const requiresBatchLink = (op: Operation) => {
  if (!enableBatchLink) return false
  const definition = getMainDefinition(op.query)
  return (
    !operationIsLoginLogout(definition) && !operationIsFormUpdater(definition)
  )
}

const httpLink = ApolloLink.split(requiresBatchLink, batchLink, noBatchLink)

const requiresHttpLink = (op: Operation) => {
  const definition = getMainDefinition(op.query)
  if (!enableQueriesOverWebsocket) {
    // Only subscriptions over websocket.
    return (
      !(
        definition.kind === 'OperationDefinition' &&
        definition.operation === 'subscription'
      ) && !operationIsFormUpdater(definition)
    )
  }
  // Everything over websocket except login/logout as that changes cookies.
  return operationIsLoginLogout(definition)
}

const actionCableLink = new ActionCableLink({ cable: consumer })

const splitLink = ApolloLink.split(requiresHttpLink, httpLink, actionCableLink)

const link = from([
  ...(VITE_TEST_MODE ? [testFlagsLink] : []),
  csrfLink,
  errorLink,
  setAuthorizationLink,
  debugLink,
  connectedStateLink,
  splitLink,
])

export default link
