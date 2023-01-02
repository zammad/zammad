// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'
import { getMainDefinition } from '@apollo/client/utilities'
import { Kind } from 'graphql'

const isEmptyResponse = (response: unknown) => {
  if (!response) return true
  if (Array.isArray(response)) return response.length === 0
  if (typeof response === 'object') {
    // eslint-disable-next-line no-restricted-syntax
    for (const key in response) {
      // eslint-disable-next-line no-continue
      if (key === '__typename') continue
      if ((response as Record<string, string>)[key]) {
        return false
      }
    }
    return true
  }
  return false
}

const counts: Record<string, number> = {}

const testFlagsLink = /* #__PURE__ */ new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    const definition = getMainDefinition(operation.query)
    if (definition.kind === Kind.FRAGMENT_DEFINITION) return response
    const operationType = definition.operation
    const operationName = definition.name?.value as string
    const operationFlag = `__gql ${operationType} ${operationName}`
    const count = counts[operationFlag] || 1
    const testFlag = `${operationFlag} ${count}`
    if (operationType === 'subscription') {
      // only trigger subscription, if it was actually returned
      // this is also triggered with empty response, when we subscribe
      if (
        response.errors ||
        (response.data && !isEmptyResponse(response.data[operationName]))
      ) {
        counts[operationFlag] = count + 1
        window.testFlags?.set(testFlag)
      }
    } else {
      counts[operationFlag] = count + 1
      window.testFlags?.set(testFlag)
    }
    return response
  })
})

export default testFlagsLink
