// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Operation } from '@apollo/client/core'
import { ApolloLink, createHttpLink, from } from '@apollo/client/core'
import type { FragmentDefinitionNode, OperationDefinitionNode } from 'graphql'
import { Kind } from 'graphql'
import consumer from '@shared/server/action_cable/consumer'
import { BatchHttpLink } from '@apollo/client/link/batch-http'
import { getMainDefinition } from '@apollo/client/utilities'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'
import csrfLink from './link/csrf'
import errorLink from './link/error'
import debugLink from './link/debug'
import setAuthorizationLink from './link/setAuthorization'
import connectedStateLink from './link/connectedState'

// Should subsequent HTTP calls be batched together?
const enableBatchLink = false

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

const requiresBatchLink = (op: Operation) => {
  if (!enableBatchLink) return false
  const definition = getMainDefinition(op.query)
  return !operationIsLoginLogout(definition)
}

const httpLink = ApolloLink.split(requiresBatchLink, batchLink, noBatchLink)

const requiresHttpLink = (op: Operation) => {
  const definition = getMainDefinition(op.query)
  if (!enableQueriesOverWebsocket) {
    // Only subscriptions over websocket.
    return !(
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    )
  }
  // Everything over websocket except login/logout as that changes cookies.
  return operationIsLoginLogout(definition)
}

const actionCableLink = new ActionCableLink({ cable: consumer })

const splitLink = ApolloLink.split(requiresHttpLink, httpLink, actionCableLink)

const testFlagLink = VITE_TEST_MODE
  ? new ApolloLink((operation, forward) => {
      return forward(operation).map((response) => {
        const definition = getMainDefinition(operation.query)
        if (definition.kind === Kind.FRAGMENT_DEFINITION) return response
        const operationType = definition.operation
        const operationName = definition.name?.value
        const flag = `__gql ${operationType} ${operationName}`
        window.testFlags?.set(flag)
        return response
      })
    })
  : null

const link = from([
  ...(testFlagLink ? [testFlagLink] : []),
  csrfLink,
  errorLink,
  setAuthorizationLink,
  debugLink,
  connectedStateLink,
  splitLink,
])

export default link
